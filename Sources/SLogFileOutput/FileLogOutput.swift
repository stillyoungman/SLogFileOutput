import Foundation
import SLog

#if os(iOS)
import UIKit
#endif

public class FileLogOutput: LogOutput {
    private static var serialQueue = DispatchQueue(label: "FileLogOutputSerialQueue",
                                                   qos: .default)
    private static var flushQueue = DispatchQueue(label: "FileLogOutputSerialQueueFlashOperation",
                                                   qos: .userInitiated)
    private static let defaultDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSZ"
        return dateFormatter
    }()

    private let fileNameProvider: LogOutputFileNameProvider
    private let messageConverter: TemplatedMessageConverter
    private let stringifyLevel: (Level) -> String
    private let dateFormatter: DateFormatter
    private let maxBufferSize: Int
    private let logFilePath: URL

    private var buffer: [String] = []

    public init(level: Level = .debug,
                messageConverter: TemplatedMessageConverter? = nil,
                dateFormatter: DateFormatter? = nil,
                maxBufferSize: Int = 10_000,
                fileNameProvider: LogOutputFileNameProvider? = nil,
                stringifyLevel: ((Level) -> String)? = nil) {
        self.messageConverter = messageConverter ?? DefaultMessageConverter.instance
        self.dateFormatter = dateFormatter ?? Self.defaultDateFormatter
        self.maxBufferSize = maxBufferSize
        self.fileNameProvider = fileNameProvider ?? DefaultLogOutputFileNameProvider.instance
        self.logFilePath = self.fileNameProvider.nextLogUrl()
        self.stringifyLevel = stringifyLevel ?? Self.getSign(of:)

        #if os(iOS)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(didEnterBackground(_:)),
                         name: UIApplication.willResignActiveNotification,
                         object: nil)

        NotificationCenter.default
            .addObserver(self, selector: #selector(willTerminate(_:)),
                         name: UIApplication.willTerminateNotification,
                         object: nil)
        #endif

        // add new line when log output created.
        try? "\n".data(using: .utf8)?.append(fileURL: logFilePath)
    }

    public func log(level: Level, message: Message, source: String?,
                    file: String, function: String, line: UInt) {
        let date = dateFormatter.string(from: Date())
        let source = source ?? "#unknown"
        Self.serialQueue.async { [weak self] in
            guard let self = self else { return }
            let logMessage = "\(date) [\(self.stringifyLevel(level))][\(source)] \(self.convert(message)) [\(function) line:\(line)]"
            self.buffer.append(logMessage)

            if self.buffer.count >= self.maxBufferSize {
                self.flush()
            }
        }
    }

    static func getSign(of level: Level) -> String {
        switch level {
        case .trace: return "🟣"
        case .debug: return "⚪️"
        case .info: return "🟢"
        case .notice: return "🔵"
        case .warning: return "🟡"
        case .error: return "🔴"
        case .critical: return "⚫️"
        }
    }

    public func removeLogs(olderThan date: Date) {
        Self.serialQueue.sync {
            for fileUrl in fileNameProvider.getUrlsOfFilesOlderThan(date) {
                try? FileManager.default.removeItem(at: fileUrl)
            }
        }
    }

    public var archivedLogs: Data? {
        // dump pending buffered logs before export
        flush()

        let logFilesUrls = fileNameProvider
            .getUrlsOfFilesOlderThan(Calendar.current.date(byAdding: .year, value: 1,
                                                           to: Date()) ?? Date())

        if let tempFolderUrl = fileNameProvider.tempDirectoryUrl {
            do {
                defer {
                    try? FileManager.default.removeItem(at: tempFolderUrl)
                }
                try FileManager.default.createDirectory(atPath: tempFolderUrl.path,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)

                for url in logFilesUrls {
                    FileManager.default
                        .secureCopyItem(at: url,
                                        to: tempFolderUrl
                                            .appendingPathComponent(url.lastPathComponent))
                }

                let arhiveUrl = tempFolderUrl.appendingPathComponent("logs.zip")
                var arhiveUrlHasValidData = false

                // create zip archive
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(readingItemAt: tempFolderUrl,
                                       options: .forUploading,
                                       error: nil) { zipUrl in
                    if FileManager.default.secureCopyItem(at: zipUrl, to: arhiveUrl) {
                        arhiveUrlHasValidData = true
                    }
                }

                return arhiveUrlHasValidData ? try? Data(contentsOf: arhiveUrl) : nil
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            print("Unable to create temporary folder URI.")
            return nil
        }
    }



    #if os(iOS)
    @objc func didEnterBackground(_ notification: NSNotification) {
        guard let application = notification.object as? UIApplication else {
            return
        }

        let task: UIBackgroundTaskIdentifier = application.beginBackgroundTask(expirationHandler: nil)
        if task == .invalid {
            // Perform flush() synchronously.
            flush()
        } else {
            // Perform flush() asynchronously.
            DispatchQueue.global().async { [weak self] in
                self?.flush()
                application.endBackgroundTask(task)
            }
        }
    }

    @objc func willTerminate(_ notification: NSNotification) {
        flush()
    }
    #endif

    private func flush() {
        if buffer.isEmpty { return }

        Self.flushQueue.sync {
            do {
                try buffer.joined(separator: "\n")
                    .appending("\n")
                    .data(using: .utf8)?
                    .append(fileURL: logFilePath)

                buffer = []
            } catch {
                log(level: .error, message: .regular(error.localizedDescription),
                    source: nil, file: #file, function: #function, line: #line)
            }
        }
    }

    private func convert(_ message: Message) -> String {
        switch message {
        case .regular(let value):
            return value
        case .templated(let templated, let args):
            return messageConverter.convertToString(templated: templated, arguments: args)
        }
    }

    deinit {
        flush()
        #if os(iOS)
        NotificationCenter.default.removeObserver(self)
        #endif
    }
}
