import Foundation
import SLog

class DefaultLogOutputFileNameProvider: LogOutputFileNameProvider {
    static let instance: DefaultLogOutputFileNameProvider = .init()

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    func createLogFileName(with date: Date? = nil) -> String {
        let dateString = dateFormatter.string(from: date ?? Date())
        return "log_\(dateString).log"
    }
    func extractDateStringFromFileName(_ fileName: String) -> String {
        fileName.replacingOccurrences(of: "log_", with: "")
            .replacingOccurrences(of: ".log", with: "")
    }

    func nextLogUrl() -> URL {
        logStorageDirectoryUrl.appendingPathComponent(createLogFileName())
    }

    func getUrlsOfFilesOlderThan(_ date: Date) -> [URL] {
        do {
            return (try FileManager.default
                                .contentsOfDirectory(at: logStorageDirectoryUrl,
                                                     includingPropertiesForKeys: nil))
                .map { $0.lastPathComponent }
                .map { extractDateStringFromFileName($0) }
                .compactMap { dateFormatter.date(from: $0) }
                .filter { $0 < date }
                .map { logStorageDirectoryUrl.appendingPathComponent(createLogFileName(with: $0)) }
        } catch {
            return []
        }
    }

    var logStorageDirectoryUrl: URL {
        (try? FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask, appropriateFor: nil,
                                     create: true))
            ?? URL.init(fileURLWithPath: "")
    }

    var tempDirectoryUrl: URL? {
        URL.init(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(dateFormatter.string(from: Date()), isDirectory: true)
    }
}
