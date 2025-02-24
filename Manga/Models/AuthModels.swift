
import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let refreshExpiresIn: Int?
    let tokenType: String?
    let notBeforePolicy: Int?
    let sessionState: String?
    let scope: String?
    let clientType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
        case tokenType = "token_type"
        case notBeforePolicy = "not-before-policy"
        case sessionState = "session_state"
        case scope
        case clientType = "client_type"
    }
}

struct LoginCredentials {
    let username: String
    let password: String
    let clientId: String
    let clientSecret: String
}
