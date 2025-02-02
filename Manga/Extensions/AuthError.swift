import Foundation
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
