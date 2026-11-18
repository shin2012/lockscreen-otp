import Foundation

public struct OTPAccount: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var label: String
    public var secret: Data
    public var digits: Int
    public var period: Int
    public var algorithm: OTPAlgorithm
    public init(id: UUID = UUID(), label: String, secret: Data, digits: Int = 6, period: Int = 30, algorithm: OTPAlgorithm = .sha1) {
        self.id = id; self.label = label; self.secret = secret
        self.digits = digits; self.period = period; self.algorithm = algorithm
    }
    public static let demo = OTPAccount(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, label: "시험", secret: Data("12345678901234567890".utf8))
}
