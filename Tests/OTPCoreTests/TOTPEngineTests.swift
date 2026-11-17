import Foundation
import XCTest
@testable import OTPCore

final class TOTPEngineTests: XCTestCase {
    func testRFC6238AllAlgorithms() throws {
        let times: [TimeInterval] = [59, 1111111109, 1111111111, 1234567890, 2000000000, 20000000000]
        let vectors: [(OTPAlgorithm, String, [String])] = [
            (.sha1, "12345678901234567890", ["94287082", "07081804", "14050471", "89005924", "69279037", "65353130"]),
            (.sha256, "12345678901234567890123456789012", ["46119246", "68084774", "67062674", "91819424", "90698825", "77737706"]),
            (.sha512, "1234567890123456789012345678901234567890123456789012345678901234", ["90693936", "25091201", "99943326", "93441116", "38618901", "47863826"])
        ]
        for (algorithm, key, expected) in vectors {
            for (time, code) in zip(times, expected) {
                XCTAssertEqual(try TOTPEngine.code(secret: Data(key.utf8), timestamp: time, digits: 8, algorithm: algorithm), code, "\(algorithm) at \(time)")
            }
        }
    }

    func testRejectsInvalidDigits() {
        XCTAssertThrowsError(try TOTPEngine.code(secret: Data("key".utf8), timestamp: 59, digits: 7))
    }

    func testCustomPeriodAndLeadingZero() throws {
        let secret = Data("12345678901234567890".utf8)
        XCTAssertEqual(try TOTPEngine.code(secret: secret, timestamp: 118, digits: 8, period: 60), "94287082")
        XCTAssertEqual(try TOTPEngine.code(secret: secret, timestamp: 1111111109, digits: 8), "07081804")
    }

    func testRFC6238SHA1At59Seconds() throws {
        let secret = Data("12345678901234567890".utf8)
        XCTAssertEqual(try TOTPEngine.code(secret: secret, timestamp: 59, digits: 8), "94287082")
    }
}
