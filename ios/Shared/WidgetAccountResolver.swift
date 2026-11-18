import Foundation

public enum WidgetAccountResolution: Equatable, Sendable {
    case account(OTPAccount)
    case notAllowed
    case missing
}

/// Picks the account a lock screen widget shows.
/// The widget's own choice wins; with no choice it follows the app's selection.
/// Real keys are only used after the app-level widget opt-in; the public test key never needs it.
public enum WidgetAccountResolver {
    public static func resolve(accounts: [OTPAccount], selectedID: UUID?, demoMode: Bool, widgetsEnabled: Bool, requestedID: String?) -> WidgetAccountResolution {
        let target: OTPAccount?
        if let requestedID {
            if requestedID == OTPAccount.demo.id.uuidString { return .account(.demo) }
            target = accounts.first { $0.id.uuidString == requestedID }
        } else if demoMode {
            return .account(.demo)
        } else {
            target = accounts.first { $0.id == selectedID }
        }
        guard let target else { return .missing }
        return widgetsEnabled ? .account(target) : .notAllowed
    }
}
