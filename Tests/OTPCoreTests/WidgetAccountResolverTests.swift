import XCTest
@testable import OTPCore

final class WidgetAccountResolverTests: XCTestCase {
    private let a = OTPAccount(label: "깃허브", secret: Data("12345678901234567890".utf8))
    private let b = OTPAccount(label: "구글", secret: Data("12345678901234567890".utf8))

    func testRequestedAccountWinsOverAppSelection() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a, b], selectedID: a.id, widgetsEnabled: true, requestedID: b.id.uuidString), .account(b))
    }

    func testFallsBackToAppSelectionThenFirstAccount() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a, b], selectedID: b.id, widgetsEnabled: true, requestedID: nil), .account(b))
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a, b], selectedID: nil, widgetsEnabled: true, requestedID: nil), .account(a))
    }

    func testRealAccountRequiresWidgetOptIn() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a], selectedID: nil, widgetsEnabled: false, requestedID: a.id.uuidString), .notAllowed)
    }

    func testDeletedOrNoAccountIsMissing() {
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [a], selectedID: nil, widgetsEnabled: true, requestedID: UUID().uuidString), .missing)
        XCTAssertEqual(WidgetAccountResolver.resolve(accounts: [], selectedID: nil, widgetsEnabled: true, requestedID: nil), .missing)
    }
}
