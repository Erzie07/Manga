import Foundation

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    
    let keychainHelper = KeychainHelper()
    private let defaults = UserDefaults.standard
    
    init() {
        restoreAuthenticationState()
    }
    
    // Define ErrorResponse inside the class
    struct ErrorResponse: Codable {
        let error: String
        let errorDescription: String
        
        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
        }
    }
    
    
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
    
    private func encodeFormData(_ parameters: [String: String]) -> Data {
        let bodyString = parameters
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        return bodyString.data(using: .utf8) ?? Data()
    }
    
    func logout() {
        keychainHelper.deleteTokens()
        defaults.removeObject(forKey: "currentUser")
        defaults.removeObject(forKey: "lastClientId")
        defaults.removeObject(forKey: "lastClientSecret")
        isAuthenticated = false
        currentUser = nil
    }
    
    private func restoreAuthenticationState() {
        if let accessToken = keychainHelper.getAccessToken(),
           let refreshToken = keychainHelper.getRefreshToken(),
           let savedUsername = defaults.string(forKey: "currentUser") {
            
            // Validate tokens and refresh if needed
            Task {
                do {
                    try await validateAndRefreshTokenIfNeeded()
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.currentUser = savedUsername
                    }
                } catch {
                    print("Failed to restore auth state: \(error)")
                    await MainActor.run {
                        self.logout()
                    }
                }
            }
        }
    }
    
    func validateAndRefreshTokenIfNeeded() async throws {
        guard let token = keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        let url = URL(string: "https://api.mangadex.org/auth/check")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                // Token expired, refresh it
                try await refreshAccessToken()
            } else if httpResponse.statusCode != 200 {
                throw AuthError.serverError("Token validation failed")
            }
        }
    }
    
    func login(credentials: LoginCredentials) async throws {
        let url = URL(string: "https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token")!
        
        let parameters = [
            "grant_type": "password",
            "username": credentials.username,
            "password": credentials.password,
            "client_id": credentials.clientId,
            "client_secret": credentials.clientSecret
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodeFormData(parameters)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // First try to decode without any key decoding strategy
                let decoder = JSONDecoder()
                
                do {
                    let authResponse = try decoder.decode(AuthResponse.self, from: data)
                    
                    await MainActor.run {
                        self.keychainHelper.saveAccessToken(authResponse.accessToken)
                        if let refreshToken = authResponse.refreshToken {
                            self.keychainHelper.saveRefreshToken(refreshToken)
                        }
                        self.defaults.set(credentials.username, forKey: "currentUser")
                        self.defaults.set(credentials.clientId, forKey: "lastClientId")
                        self.defaults.set(credentials.clientSecret, forKey: "lastClientSecret")
                        self.isAuthenticated = true
                        self.currentUser = credentials.username
                    }
                } catch {
                    // Log the error for debugging
                    print("Decoding error: \(error)")
                    
                    // Let's try to decode it manually as a fallback
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let accessToken = json["access_token"] as? String,
                       let refreshToken = json["refresh_token"] as? String {
                        
                        await MainActor.run {
                            self.keychainHelper.saveAccessToken(accessToken)
                            self.keychainHelper.saveRefreshToken(refreshToken)
                            self.defaults.set(credentials.username, forKey: "currentUser")
                            self.defaults.set(credentials.clientId, forKey: "lastClientId")
                            self.defaults.set(credentials.clientSecret, forKey: "lastClientSecret")
                            self.isAuthenticated = true
                            self.currentUser = credentials.username
                        }
                    } else {
                        throw AuthError.serverError("Failed to decode response")
                    }
                }
            } else {
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorData.errorDescription)
                } else {
                    throw AuthError.serverError("Login failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch let error as AuthError {
            throw error
        } catch {
            print("Unexpected error during login: \(error)")
            throw AuthError.networkError
        }
    }
    
    
    func refreshAccessToken() async throws {
        guard let refreshToken = keychainHelper.getRefreshToken(),
              let clientId = defaults.string(forKey: "lastClientId"),
              let clientSecret = defaults.string(forKey: "lastClientSecret") else {
            throw AuthError.refreshFailed
        }
        
        let url = URL(string: "https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token")!
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodeFormData(parameters)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                
                await MainActor.run {
                    self.keychainHelper.saveAccessToken(authResponse.accessToken)
                    if let newRefreshToken = authResponse.refreshToken {
                        self.keychainHelper.saveRefreshToken(newRefreshToken)
                    }
                    self.isAuthenticated = true
                }
            } else {
                await MainActor.run {
                    self.logout()
                }
                throw AuthError.refreshFailed
            }
        } catch {
            await MainActor.run {
                self.logout()
            }
            throw AuthError.refreshFailed
        }
    }
}
