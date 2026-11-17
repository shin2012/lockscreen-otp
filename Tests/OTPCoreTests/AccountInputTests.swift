import Foundation
import XCTest
@testable import OTPCore

final class AccountInputTests: XCTestCase {
    func testRFC4648Base32() throws {
        for (encoded, decoded) in [("MY======", "f"), ("MZXQ====", "fo"), ("MZXW6===", "foo"), ("MZXW6YQ=", "foob"), ("MZXW6YTB", "fooba"), ("MZXW6YTBOI======", "foobar")] {
            XCTAssertEqual(try Base32.decode(encoded), Data(decoded.utf8))
            XCTAssertEqual(try Base32.decode(encoded.lowercased().replacingOccurrences(of: "=", with: "")), Data(decoded.utf8))
        }
    }
    func testRejectsMalformedBase32() {
        for input in ["", "A", "M0", "MZ", "MY=AAAAA", "MY=====", "☃", "MY======A"] {
            XCTAssertThrowsError(try Base32.decode(input), input)
        }
    }
    func testImportsTOTPWithExplicitParameters() throws {
        let a = try OTPURIParser.parse("otpauth://totp/Example%3Aalice?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example&algorithm=SHA256&digits=8&period=60")
        XCTAssertEqual(a.label, "Example:alice")
        XCTAssertEqual(a.secret, Data("12345678901234567890".utf8))
        XCTAssertEqual(a.algorithm, .sha256)
        XCTAssertEqual(a.digits, 8)
        XCTAssertEqual(a.period, 60)
    }
    func testRejectsUnsupportedOrAmbiguousURIs() {
        for uri in ["https://example.com/?secret=MY", "otpauth://hotp/A?secret=MY&counter=0", "otpauth://totp/A?secret=MY&secret=MZXQ", "otpauth://totp/A?secret=MY&digits=7", "otpauth://totp/A?secret=MY&period=0", "otpauth://totp/A?secret=MY&algorithm=MD5", "otpauth://totp/?secret=MY", "otpauth://totp/A"] {
            XCTAssertThrowsError(try OTPURIParser.parse(uri))
        }
    }
}
