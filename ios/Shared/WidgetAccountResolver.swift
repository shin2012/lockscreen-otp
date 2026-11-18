import Foundation

public enum WidgetAccountResolution: Equatable, Sendable {
    case account(OTPAccount)
    case notAllowed
    case missing
}

/// Picks the account a lock screen widget shows.
/// The widget's own choice wins; otherwise the app's default account, then the first account.
/// Keys are only used after the app-level widget opt-in.
public enum WidgetAccountResolver {
    public static func resolve(accounts: [OTPAccount], selectedID: UUID?, widgetsEnabled: Bool, requestedID: String?) -> WidgetAccountResolution {
        let target: OTPAccount?
        if let requestedID {
            target = accounts.first { $0.id.uuidString == requestedID }
        } else {
            target = accounts.first { $0.id == selectedID } ?? accounts.first
        }
        guard let target else { return .missing }
        return widgetsEnabled ? .account(target) : .notAllowed
    }
}
