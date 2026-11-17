import Foundation
import XCTest
@testable import OTPCore

final class InputModeTests: XCTestCase {
    // Base32 encoding of the public RFC 6238 test vector, not an account key.
    private let rfcBase32Vector = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
    func testManualModeNeverPrefersOtherField() throws {
        let account = try OTPAccountInput.build(mode: .manual, label: "시험", secret: rfcBase32Vector, uri: "not-a-registration-uri")
        XCTAssertEqual(account.label, "시험")
        XCTAssertEqual(account.secret, OTPAccount.demo.secret)
    }
    func testURIModeUsesOnlySelectedMethod() throws {
        let account = try OTPAccountInput.build(mode: .uri, label: "ignored", secret: "invalid", uri: "otpauth://totp/Example?secret=\(rfcBase32Vector)")
        XCTAssertEqual(account.label, "Example")
        XCTAssertEqual(account.secret, OTPAccount.demo.secret)
        XCTAssertThrowsError(try OTPAccountInput.build(mode: .uri, label: "시험", secret: rfcBase32Vector, uri: "invalid"))
    }
}
