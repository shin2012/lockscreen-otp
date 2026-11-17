import XCTest

final class OTPAppUITests: XCTestCase {
    func testLaunchDemoAndRejectInvalidInput() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["잠금 OTP"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["공개 시험키"].exists)
        app.buttons["add-account"].tap()
        XCTAssertTrue(app.textFields["account-label"].waitForExistence(timeout: 5))
        app.buttons["save-account"].tap()
        XCTAssertTrue(app.staticTexts["input-error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["계정 이름을 1~120자로 입력하세요."].exists)
        app.buttons["취소"].tap()
        app.tabBars.buttons["검증"].tap()
        XCTAssertTrue(app.navigationBars["자동 갱신 검증"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "demo-diagnostics"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
