import XCTest

final class OTPAppUITests: XCTestCase {
    func testLaunchDemoAndRejectInvalidInput() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["잠금 OTP"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["공개 시험키"].exists)
        app.buttons["add-account"].tap()
        XCTAssertTrue(app.textFields["account-label"].waitForExistence(timeout: 5))
        app.buttons["save-account"].tap()
        XCTAssertTrue(app.staticTexts["input-error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["계정 이름을 1~120자로 입력하세요."].exists)
        let name = app.textFields["account-label"]
        name.tap()
        name.typeText("검증 계정")
        XCTAssertEqual(name.value as? String, "검증 계정")
        let secret = app.secureTextFields["account-secret"]
        secret.tap()
        // RFC 6238 public fixture, never a real account secret.
        secret.typeText("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        app.buttons["save-account"].tap()
        XCTAssertTrue(app.staticTexts["검증 계정"].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["검증 계정"].waitForExistence(timeout: 15))
        let row = app.cells.containing(.staticText, identifier: "검증 계정").firstMatch
        XCTAssertTrue(row.exists)
        row.swipeLeft()
        app.buttons["삭제"].tap()
        // iOS 26 exposes the dialog button and its wrapper with the same identifier.
        let confirm = app.buttons.matching(identifier: "confirm-delete").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["등록된 계정이 없습니다."].waitForExistence(timeout: 5))
        app.tabBars.buttons["위젯"].tap()
        let demo = app.switches["시험키 사용"]
        XCTAssertTrue(demo.waitForExistence(timeout: 5))
        demo.tap()
        app.tabBars.buttons["검증"].tap()
        XCTAssertTrue(app.navigationBars["자동 갱신 검증"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "demo-diagnostics"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
