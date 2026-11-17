import SwiftUI
import WidgetKit

@main
struct OTPApp: App {
    @StateObject private var store = VaultStore()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
                .overlay {
                    if phase != .active {
                        Rectangle().fill(.background).overlay {
                            Label("잠금 OTP", systemImage: "lock.shield")
                        }.ignoresSafeArea()
                    }
                }
                .onChange(of: phase) { _, value in if value == .active { store.reload() } }
        }
    }
}

@MainActor
final class VaultStore: ObservableObject {
    @Published private(set) var vault = OTPVault()
    @Published private(set) var ready = false
    @Published var error: String?
    @Published private(set) var requestedAt: Date?
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
            requestReload()
        } catch { self.error = error.localizedDescription }
    }
    func requestReload() {
        WidgetCenter.shared.reloadAllTimelines()
        requestedAt = Date()
    }
}
