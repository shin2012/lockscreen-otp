import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum OTPAlgorithm: String, Codable, Sendable { case sha1, sha256, sha512 }
public enum OTPError: Error { case invalidDigits, invalidPeriod, emptySecret, invalidTime, invalidCount }

public enum TOTPEngine {
    public static func code(secret: Data, timestamp: TimeInterval, digits: Int = 6, period: Int = 30, algorithm: OTPAlgorithm = .sha1) throws -> String {
        guard digits == 6 || digits == 8 else { throw OTPError.invalidDigits }
        guard period > 0 else { throw OTPError.invalidPeriod }
        guard !secret.isEmpty else { throw OTPError.emptySecret }
        guard timestamp.isFinite, timestamp >= 0,
              timestamp / Double(period) < Double(UInt64.max) else { throw OTPError.invalidTime }
        let counter = UInt64(timestamp / Double(period))
        var value = counter.bigEndian
        let message = withUnsafeBytes(of: &value) { Data($0) }
        let key = SymmetricKey(data: secret)
        let digest: [UInt8]
        switch algorithm {
        case .sha1: digest = Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key))
        case .sha256: digest = Array(HMAC<SHA256>.authenticationCode(for: message, using: key))
        case .sha512: digest = Array(HMAC<SHA512>.authenticationCode(for: message, using: key))
        }
        let offset = Int(digest.last! & 0x0f)
        let binary = digest[offset..<(offset + 4)].reduce(UInt32(0)) { ($0 << 8) | UInt32($1) } & 0x7fff_ffff
        let modulus: UInt32 = digits == 8 ? 100_000_000 : 1_000_000
        return String(format: "%0*d", digits, binary % modulus)
    }
}
