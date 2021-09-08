import Foundation

public protocol FileNameProviderProtocol {
    func nextLogUrl() -> URL?
    func getUrlsOfFilesOlderThan(_ date: Date) -> [URL]
    var urlsOfLogFilesSortedByDate: [URL] { get }
    var urlsOfLogFilesSortedByIndex: [URL] { get }
    var logStorageDirectoryUrl: URL? { get }
    var tempDirectoryUrl: URL? { get }
}
