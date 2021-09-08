import Foundation

struct LogName: Codable {
    var index: UInt
    var dateString: String

    enum CodingKeys: String, CodingKey {
        case index = "i"
        case dateString = "d"
    }
}
