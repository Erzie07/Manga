import Foundation

class KeychainHelper {
    private let accessTokenKey = "mangadex.accessToken"
    private let refreshTokenKey = "mangadex.refreshToken"
    
    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }
    
    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }
    
    func deleteTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }
    
    private func save(_ string: String, forKey key: String) {
        let data = string.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
