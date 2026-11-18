import SwiftUI
import WidgetKit
import AppKit

@main
struct MacOTPApp: App {
    @StateObject private var store = VaultStore()
    var body: some Scene {
        WindowGroup("잠금 OTP") {
            MacRootView().environmentObject(store)
                .frame(minWidth: 420, minHeight: 420)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in store.reload() }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("계정 추가…") { NotificationCenter.default.post(name: .otpAddAccount, object: nil) }
                    .keyboardShortcut("n")
            }
        }
        Settings {
            MacSettingsView().environmentObject(store).frame(width: 460)
        }
    }
}

extension Notification.Name {
    static let otpAddAccount = Notification.Name("otpAddAccount")
}

@MainActor
final class VaultStore: ObservableObject {
    @Published private(set) var vault = OTPVault()
    @Published private(set) var ready = false
    @Published var error: String?
    init() { reload() }
    func reload() {
        do { vault = try KeychainVault.load(); ready = true }
        catch { ready = false; self.error = error.localizedDescription }
    }
    func change(_ update: (inout OTPVault) -> Void) {
        guard ready else { return }
        var next = vault
        update(&next)
        do {
            try KeychainVault.save(next)
            vault = next
            WidgetCenter.shared.reloadAllTimelines()
        } catch { self.error = error.localizedDescription }
    }
}
