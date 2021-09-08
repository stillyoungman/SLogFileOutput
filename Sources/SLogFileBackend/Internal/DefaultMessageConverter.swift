import Foundation
import SLog

class DefaultMessageConverter: TemplatedMessageConverter {
    static let instance: TemplatedMessageConverter = DefaultMessageConverter()

    private init() { }

    func convertToString(templated: String, arguments: [TypeWrapper]) -> String {
        String(format: templated, arguments: arguments.map { $0.description })
    }
}
