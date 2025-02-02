import Foundation

class LibraryManager: ObservableObject {
    @Published private(set) var libraryManga: [String: (Manga, MangaReadingStatus)] = [:]
    @Published private(set) var isSyncing = false
    @Published var error: Error?
    
    private let authManager: AuthenticationManager
    private let limit = 100
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        // Don't automatically sync - we'll do it when needed
    }
    
    private func validateAndRefreshTokenIfNeeded() async throws -> String {
        guard let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        // Check if token needs refresh
        let url = URL(string: "https://api.mangadex.org/auth/check")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                // Token expired, try to refresh
                try await authManager.refreshAccessToken()
                // Get new token after refresh
                guard let newToken = authManager.keychainHelper.getAccessToken() else {
                    throw AuthError.tokenExpired
                }
                return newToken
            } else if httpResponse.statusCode != 200 {
                throw AuthError.serverError("Token validation failed")
            }
        }
        
        return token
    }
    
    func syncLibrary() async {
        guard authManager.isAuthenticated else {
            await MainActor.run {
                error = AuthError.tokenExpired
            }
            return
        }
        
        await MainActor.run {
            isSyncing = true
            error = nil
        }
        
        do {
            // Validate and refresh token if needed
            let token = try await validateAndRefreshTokenIfNeeded()
            
            // Now proceed with library sync using valid token
            let statusUrl = URL(string: "https://api.mangadex.org/manga/status")!
            var statusRequest = URLRequest(url: statusUrl)
            statusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (statusData, statusResponse) = try await URLSession.shared.data(for: statusRequest)
            
            guard let httpStatusResponse = statusResponse as? HTTPURLResponse,
                  httpStatusResponse.statusCode == 200 else {
                throw AuthError.serverError("Failed to fetch reading status")
            }
            
            struct ReadingStatusResponse: Codable {
                let statuses: [String: String]
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let statusResult = try decoder.decode(ReadingStatusResponse.self, from: statusData)
            
            var updatedLibrary: [String: (Manga, MangaReadingStatus)] = [:]
            
            try await withThrowingTaskGroup(of: (String, (Manga, MangaReadingStatus))?.self) { group in
                for (mangaId, statusString) in statusResult.statuses {
                    guard let status = MangaReadingStatus(rawValue: statusString) else { continue }
                    
                    group.addTask {
                        do {
                            let manga = try await self.fetchMangaDetails(id: mangaId)
                            return (mangaId, (manga, status))
                        } catch {
                            print("Error fetching manga \(mangaId): \(error)")
                            return nil
                        }
                    }
                }
                
                for try await result in group {
                    if let (id, entry) = result {
                        updatedLibrary[id] = entry
                    }
                }
            }
            
            await MainActor.run {
                self.libraryManga = updatedLibrary
                self.isSyncing = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isSyncing = false
            }
        }
    }
    

    
    func updateMangaStatus(_ manga: Manga, status: MangaReadingStatus?) async throws {
        guard authManager.isAuthenticated,
              let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        let url = URL(string: "https://api.mangadex.org/manga/\(manga.id)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct StatusRequest: Codable {
            let status: String?
        }
        
        // If status is nil, it removes the manga from library
        let body = StatusRequest(status: status?.rawValue)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to update reading status")
        }
        
        await MainActor.run {
            if let status = status {
                self.libraryManga[manga.id] = (manga, status)
            } else {
                self.libraryManga.removeValue(forKey: manga.id)
            }
        }
    }
    
    func removeMangaFromLibrary(_ manga: Manga) async throws {
            guard authManager.isAuthenticated,
                  let token = authManager.keychainHelper.getAccessToken() else {
                throw AuthError.tokenExpired
            }
            
            let url = URL(string: "https://api.mangadex.org/manga/\(manga.id)/status")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Create request body with nil status to remove reading status
            struct StatusRequest: Codable {
                let status: String?
            }
            
            let body = StatusRequest(status: nil)
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError("Invalid response type")
            }
            
            if httpResponse.statusCode == 200 {
                await MainActor.run {
                    self.libraryManga.removeValue(forKey: manga.id)
                }
            } else {
                if let errorString = String(data: data, encoding: .utf8) {
                    throw AuthError.serverError("Failed to remove manga (Status: \(httpResponse.statusCode), Error: \(errorString))")
                } else {
                    throw AuthError.serverError("Failed to remove manga (Status: \(httpResponse.statusCode))")
                }
            }
        }
}

extension LibraryManager {
    func fetchMangaDetails(id: String) async throws -> Manga {
        let url = URL(string: "https://api.mangadex.org/manga/\(id)?includes[]=cover_art")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to fetch manga details")
        }
        
        struct SingleMangaResponse: Decodable {
            let data: Manga
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let mangaResponse = try decoder.decode(SingleMangaResponse.self, from: data)
        return mangaResponse.data
    }
}
