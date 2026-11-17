import Foundation

public enum OTPInputMode: String, CaseIterable, Sendable { case manual, uri }
public enum OTPAccountInput {
    public enum InputError: Error { case invalid, invalidLabel }
    public static func build(mode: OTPInputMode, label: String, secret: String, uri: String, digits: Int = 6, period: Int = 30, algorithm: OTPAlgorithm = .sha1) throws -> OTPAccount {
        if mode == .uri { return try OTPURIParser.parse(uri) }
        let name = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 120 else { throw InputError.invalidLabel }
        guard (1...3600).contains(period) else { throw InputError.invalid }
        let decoded = try Base32.decode(secret)
        _ = try TOTPEngine.code(secret: decoded, timestamp: 0, digits: digits, period: period, algorithm: algorithm)
        return OTPAccount(label: name, secret: decoded, digits: digits, period: period, algorithm: algorithm)
    }
}
