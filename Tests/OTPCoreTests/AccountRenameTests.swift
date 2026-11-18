import XCTest
@testable import OTPCore

final class AccountRenameTests: XCTestCase {
    private let a = OTPAccount(label: "깃허브", secret: Data("12345678901234567890".utf8), digits: 8, period: 60, algorithm: .sha256)
    private let b = OTPAccount(label: "구글", secret: Data("12345678901234567890".utf8))

    func testRenameChangesOnlyTargetLabelAndKeepsKeySettings() throws {
        let result = try OTPAccountEditor.rename([a, b], id: a.id, to: "  회사 깃허브 ")
        XCTAssertEqual(result[0].label, "회사 깃허브")
        XCTAssertEqual(result[0].id, a.id)
        XCTAssertEqual(result[0].secret, a.secret)
        XCTAssertEqual(result[0].digits, 8)
        XCTAssertEqual(result[0].period, 60)
        XCTAssertEqual(result[0].algorithm, .sha256)
        XCTAssertEqual(result[1], b)
    }

    func testRejectsBlankOrTooLongNameAndUnknownAccount() {
        XCTAssertThrowsError(try OTPAccountEditor.rename([a], id: a.id, to: "   "))
        XCTAssertThrowsError(try OTPAccountEditor.rename([a], id: a.id, to: String(repeating: "가", count: 121)))
        XCTAssertThrowsError(try OTPAccountEditor.rename([a], id: UUID(), to: "새 이름"))
    }
}
