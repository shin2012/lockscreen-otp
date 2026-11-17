import Foundation
import Security

struct OTPVault: Codable {
    var accounts: [OTPAccount] = []
    var selectedID: UUID? = nil
    var demoMode = true
    var widgetsEnabled = false
    var showWhenLocked = false
    var entryCount = 120
    var selected: OTPAccount? { demoMode ? .demo : accounts.first { $0.id == selectedID } }
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
        #if !targetEnvironment(simulator)
        if let group = Bundle.main.object(forInfoDictionaryKey: "SharedKeychainGroup") as? String,
           !group.contains("$("), !group.isEmpty { q[kSecAttrAccessGroup as String] = group }
        #endif
        return q
    }
    static func load() throws -> OTPVault {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return OTPVault() }
        guard status == errSecSuccess, let data = result as? Data else { throw VaultFailure(status: status) }
        return try JSONDecoder().decode(OTPVault.self, from: data)
    }
    static func save(_ vault: OTPVault) throws {
        let data = try JSONEncoder().encode(vault)
        let accessibility = vault.widgetsEnabled ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: accessibility]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            item[kSecAttrSynchronizable as String] = false
            let added = SecItemAdd(item as CFDictionary, nil)
            guard added == errSecSuccess else { throw VaultFailure(status: added) }
        } else if status != errSecSuccess { throw VaultFailure(status: status) }
    }
}
