import XCTest

final class OTPAppUITests: XCTestCase {
    func testAddRenameRestoreAndDeleteAccount() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["잠금 OTP"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["등록된 계정이 없습니다."].exists)
        XCTAssertFalse(app.tabBars.buttons["검증"].exists)

        app.buttons["add-account"].tap()
        XCTAssertTrue(app.textFields["account-label"].waitForExistence(timeout: 5))
        app.buttons["save-account"].tap()
        XCTAssertTrue(app.staticTexts["계정 이름을 1~120자로 입력하세요."].waitForExistence(timeout: 5))
        let name = app.textFields["account-label"]
        name.tap()
        name.typeText("검증 계정")
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
        row.swipeLeft()
        app.buttons["편집"].tap()
        let edit = app.textFields["edit-label"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        // Put the cursor after the existing text, then erase it.
        edit.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        edit.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12))
        edit.typeText("바뀐 이름")
        app.buttons["save-edit"].tap()
        XCTAssertTrue(app.staticTexts["바뀐 이름"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["검증 계정"].exists)

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "account-list"
        shot.lifetime = .keepAlways
        add(shot)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["바뀐 이름"].waitForExistence(timeout: 15))
        let renamed = app.cells.containing(.staticText, identifier: "바뀐 이름").firstMatch
        renamed.swipeLeft()
        app.buttons["삭제"].firstMatch.tap()
        // iOS 26 exposes the dialog button and its wrapper with the same identifier.
        let confirm = app.buttons.matching(identifier: "confirm-delete").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["등록된 계정이 없습니다."].waitForExistence(timeout: 5))

        app.tabBars.buttons["위젯"].tap()
        XCTAssertTrue(app.navigationBars["잠금 화면 위젯"].waitForExistence(timeout: 5))
        app.swipeUp()
        sleep(1)
        let settings = XCTAttachment(screenshot: app.screenshot())
        settings.name = "widget-settings"
        settings.lifetime = .keepAlways
        add(settings)
    }
}
