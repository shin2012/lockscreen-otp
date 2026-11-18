import XCTest
@testable import OTPCore

final class WidgetAccountResolverTests: XCTestCase {
    private let a = OTPAccount(label: "깃허브", secret: Data("12345678901234567890".utf8))
    private let b = OTPAccount(label: "구글", secret: Data("12345678901234567890".utf8))

    func testRequestedAccountWinsOverAppSelection() {
        let r = WidgetAccountResolver.resolve(accounts: [a, b], selectedID: a.id, demoMode: true, widgetsEnabled: true, requestedID: b.id.uuidString)
        XCTAssertEqual(r, .account(b))
    }

    func testFallsBackToAppSelectionWhenNothingRequested() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a, b], selectedID: b.id, demoMode: false, widgetsEnabled: true, requestedID: nil), .account(b))
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a], selectedID: a.id, demoMode: true, widgetsEnabled: false, requestedID: nil), .account(.demo))
    }

    func testRealAccountRequiresWidgetOptIn() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a], selectedID: nil, demoMode: false, widgetsEnabled: false, requestedID: a.id.uuidString), .notAllowed)
    }

    func testDemoRequestNeedsNoOptInAndDeletedAccountIsMissing() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [], selectedID: nil, demoMode: false, widgetsEnabled: false, requestedID: OTPAccount.demo.id.uuidString), .account(.demo))
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a], selectedID: nil, demoMode: false, widgetsEnabled: true, requestedID: UUID().uuidString), .missing)
    }
}
