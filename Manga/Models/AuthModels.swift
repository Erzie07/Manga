
import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    
    // Add coding keys to match server response format
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}


struct LoginCredentials {
    let username: String
    let password: String
    let clientId: String
    let clientSecret: String
}
