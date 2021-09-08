import Foundation
import SLog

class DefaultFileNameProvider: FileNameProviderProtocol {
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yyyy"
        return dateFormatter
    }()

    func createLogFileName(with date: Date?) -> String {
        let index = getCurrentIndex() + 1
        let logName = LogName(index: index, dateString: dateFormatter.string(from: date ?? Date()))
        guard let name = encode(logName) else {
            print("Unable to create encoded log name.")
            return UUID().uuidString + ".log"
        }
        return name
    }

    func getCurrentIndex() -> UInt {
        guard let lastIndexUrl = urlsOfLogFilesSortedByIndex.last,
              let index = decode(lastIndexUrl.lastPathComponent)?.index else { return 0 }

        return index
    }

    func nextLogUrl() -> URL? {
        guard let url = logStorageDirectoryUrl?
                .appendingPathComponent(createLogFileName(with: Date())) else {
            print("Can't create next log URL.")
            return nil
        }

        return url
    }

    var urlsOfLogFilesSortedByIndex: [URL] {
        guard let url = logStorageDirectoryUrl,
              let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                      includingPropertiesForKeys: nil)
        else {
            print("Can't get URL of log storage or content of the directory.")
            return []
        }

        return urls.compactMap { (url) -> (url: URL, index: UInt, date: Date)?  in
            guard let logName = decode(url.lastPathComponent),
                  let date = dateFormatter.date(from: logName.dateString)
            else { return nil }

            return (url, logName.index, date)
        }
        .sorted(by: { $0.index < $1.index })
        .map { $0.url }
    }

    var urlsOfLogFilesSortedByDate: [URL] {
        guard let url = logStorageDirectoryUrl,
              let urls = try? FileManager.default.contentsOfDirectory(at: url,
                                                                      includingPropertiesForKeys: nil)
        else {
            print("Can't get URL of log storage or content of the directory.")
            return []
        }

        return urls.compactMap { (url) -> (url: URL, index: UInt, date: Date)?  in
            guard let logName = decode(url.lastPathComponent),
                  let date = dateFormatter.date(from: logName.dateString)
            else { return nil }
            
            return (url, logName.index, date)
        }
        .sorted(by: { $0.date < $1.date })
        .map { $0.url }
    }

    var logStorageDirectoryUrl: URL? {
        let manager = FileManager.default

        guard let rootFolderURL = try? manager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            print("Can't get access of document directory.")
            return nil
        }

        let nestedFolderURL = rootFolderURL.appendingPathComponent("logs")

        if !manager.fileExists(atPath: nestedFolderURL.relativePath) {
            try? manager.createDirectory(
                at: nestedFolderURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }

        return nestedFolderURL
    }

    func getUrlsOfFilesOlderThan(_ date: Date) -> [URL] {
        guard let logStorageDirectoryUrl = logStorageDirectoryUrl else {
            print("Unable to get URL of log storage.")
            return []
        }

        return ((try? FileManager.default
            .contentsOfDirectory(at: logStorageDirectoryUrl,
                                 includingPropertiesForKeys: nil))?
            .filter { url in
                guard let logName = decode(url.lastPathComponent),
                      let fileDate = dateFormatter.date(from: logName.dateString) else {
                    return false
                }

                return fileDate < date
            }) ?? []
    }

    var tempDirectoryUrl: URL? {
        URL.init(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(dateFormatter.string(from: Date()), isDirectory: true)
    }

    func encode(_ logName: LogName) -> String? {
        try? JSONEncoder().encode(logName).base64EncodedString() + ".log"
    }

    func decode(_ string: String) -> LogName? {
        guard let base64Encoded = string.replacingOccurrences(of: ".log", with: "").data(using: .utf8),
              let data = Data(base64Encoded: base64Encoded)
        else { return nil }

        return try? JSONDecoder().decode(LogName.self, from: data)
    }
}
