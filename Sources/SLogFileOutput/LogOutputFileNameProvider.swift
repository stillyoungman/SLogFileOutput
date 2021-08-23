import Foundation

public protocol LogOutputFileNameProvider {
    func createLogFileName(with date: Date?) -> String
    func extractDateStringFromFileName(_ fileName: String) -> String
    func nextLogUrl() -> URL
    func getUrlsOfFilesOlderThan(_ date: Date) -> [URL]
    var logStorageDirectoryUrl: URL { get }
    var tempDirectoryUrl: URL? { get }
}
