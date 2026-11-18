import Foundation
import Security
import OSLog

private let vaultLog = Logger(subsystem: "kr.b-612.lockscreenotp", category: "vault")

struct OTPVault: Codable {
    var accounts: [OTPAccount] = []
    var selectedID: UUID? = nil
    var widgetsEnabled = false
    var showWhenLocked = false
    var entryCount = 120
    var selected: OTPAccount? { accounts.first { $0.id == selectedID } ?? accounts.first }
}

struct VaultFailure: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "키체인 접근 실패 (\(status)). 잠금을 해제한 뒤 다시 시도해 주세요." }
}

enum KeychainVault {
    private static let service = "kr.b-612.lockscreenotp.vault"
    private static var query: [String: Any] {
        var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrService as String: service,
                               kSecAttrAccount as String: "vault-v1"]
        if let group = Bundle.main.object(forInfoDictionaryKey: "SharedKeychainGroup") as? String,
           !group.contains("$("), !group.isEmpty { q[kSecAttrAccessGroup as String] = group }
        return q
    }
    static func load() throws -> OTPVault {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        #if DEBUG && targetEnvironment(simulator)
        vaultLog.notice("load status=\(status, privacy: .public)")
        #endif
        if status == errSecItemNotFound { return OTPVault() }
        guard status == errSecSuccess, let data = result as? Data else { throw VaultFailure(status: status) }
        let decoded = try JSONDecoder().decode(OTPVault.self, from: data)
        #if DEBUG && targetEnvironment(simulator)
        vaultLog.notice("load accounts=\(decoded.accounts.count, privacy: .public)")
        #endif
        return decoded
    }
    static func save(_ vault: OTPVault) throws {
        let data = try JSONEncoder().encode(vault)
        let accessibility = vault.widgetsEnabled ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: accessibility]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        #if DEBUG && targetEnvironment(simulator)
        vaultLog.notice("save update=\(status, privacy: .public) accounts=\(vault.accounts.count, privacy: .public)")
        #endif
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            item[kSecAttrSynchronizable as String] = false
            let added = SecItemAdd(item as CFDictionary, nil)
            #if DEBUG && targetEnvironment(simulator)
            vaultLog.notice("save add=\(added, privacy: .public)")
            #endif
            guard added == errSecSuccess else { throw VaultFailure(status: added) }
        } else if status != errSecSuccess { throw VaultFailure(status: status) }
    }
}
