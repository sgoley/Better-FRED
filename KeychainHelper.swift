import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.betterfred.app.secrets"
    private static let account = "FRED_API_KEY"
    private static let userDefaultsKey = "betterfred.api_key.fallback"

    static func saveKey(_ key: String) -> Bool {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            return deleteKey()
        }

        // Store in UserDefaults as fallback for simulator instances where Keychain access groups may be restricted
        UserDefaults.standard.set(cleanKey, forKey: userDefaultsKey)

        guard let data = cleanKey.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newQuery as CFDictionary, nil)
        return status == errSecSuccess || status == errSecDuplicateItem
    }

    static func loadKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data, let key = String(data: data, encoding: .utf8), !key.isEmpty {
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Check UserDefaults fallback
        if let fallback = UserDefaults.standard.string(forKey: userDefaultsKey), !fallback.isEmpty {
            return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    static func deleteKey() -> Bool {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
