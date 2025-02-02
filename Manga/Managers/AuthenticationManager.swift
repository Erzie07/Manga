import Foundation

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    
    let keychainHelper = KeychainHelper()
    private let defaults = UserDefaults.standard
    
    // Nested error type
    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case networkError
        case serverError(String)
        case tokenExpired
        case refreshFailed
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid username or password"
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .serverError(let message):
                return "Server error: \(message)"
            case .tokenExpired:
                return "Your session has expired. Please log in again."
            case .refreshFailed:
                return "Failed to refresh authentication. Please log in again."
            case .unknownError:
                return "An unexpected error occurred. Please try again."
            }
        }
    }
    
    init() {
        restoreAuthenticationState()
    }
    
    private func restoreAuthenticationState() {
        // If we have both tokens and a saved username, restore the authenticated state
        if let accessToken = keychainHelper.getAccessToken(),
           let refreshToken = keychainHelper.getRefreshToken(),
           let savedUsername = defaults.string(forKey: "currentUser") {
            
            // Validate the access token and refresh if needed
            Task {
                do {
                    if await shouldRefreshToken() {
                        try await refreshAccessToken()
                    }
                    
                    // Update the authentication state on success
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.currentUser = savedUsername
                    }
                } catch {
                    // If token refresh fails, clear everything and require new login
                    await MainActor.run {
                        self.logout()
                    }
                }
            }
        }
    }
    
    private func shouldRefreshToken() async -> Bool {
        // Verify the current access token
        guard let accessToken = keychainHelper.getAccessToken() else {
            return true
        }
        
        // Make a test request to check token validity
        let url = URL(string: "https://api.mangadex.org/auth/check")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 401
        } catch {
            return true
        }
    }
    
        func refreshAccessToken() async throws {
            // Get the current refresh token
            guard let refreshToken = keychainHelper.getRefreshToken() else {
                throw AuthError.refreshFailed
            }
            
            let url = URL(string: "https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            // Get stored client credentials
            guard let clientId = UserDefaults.standard.string(forKey: "lastClientId"),
                  let clientSecret = UserDefaults.standard.string(forKey: "lastClientSecret") else {
                throw AuthError.refreshFailed
            }
            
            // Prepare the refresh token request body
            let bodyParams = [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "client_id": clientId,
                "client_secret": clientSecret
            ]
            
            let bodyString = bodyParams
                .map { key, value in
                    let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(encodedKey)=\(encodedValue)"
                }
                .joined(separator: "&")
            
            request.httpBody = bodyString.data(using: .utf8)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.networkError
                }
                
                if httpResponse.statusCode == 200 {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    
                    // Update stored tokens
                    await MainActor.run {
                        self.keychainHelper.saveAccessToken(authResponse.accessToken)
                        self.keychainHelper.saveRefreshToken(authResponse.refreshToken)
                    }
                } else {
                    throw AuthError.refreshFailed
                }
            } catch {
                throw AuthError.refreshFailed
            }
        }
    
    func login(credentials: LoginCredentials) async throws {
        // Store client credentials for future token refreshes
        UserDefaults.standard.set(credentials.clientId, forKey: "lastClientId")
        UserDefaults.standard.set(credentials.clientSecret, forKey: "lastClientSecret")
        
        let url = URL(string: "https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "password",
            "username": credentials.username,
            "password": credentials.password,
            "client_id": credentials.clientId,
            "client_secret": credentials.clientSecret
        ]
        
        let bodyString = bodyParams
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                await MainActor.run {
                    self.keychainHelper.saveAccessToken(authResponse.accessToken)
                    self.keychainHelper.saveRefreshToken(authResponse.refreshToken)
                    self.defaults.set(credentials.username, forKey: "currentUser")
                    self.isAuthenticated = true
                    self.currentUser = credentials.username
                }
                
            case 401:
                throw AuthError.invalidCredentials
                
            default:
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error_description"] as? String {
                    throw AuthError.serverError(errorMessage)
                } else {
                    throw AuthError.serverError("Status code: \(httpResponse.statusCode)")
                }
            }
            
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }
    
    func logout() {
        keychainHelper.deleteTokens()
        defaults.removeObject(forKey: "currentUser")
        defaults.removeObject(forKey: "lastClientId")
        defaults.removeObject(forKey: "lastClientSecret")
        isAuthenticated = false
        currentUser = nil
    }
}
