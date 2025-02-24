import Foundation
import UIKit
import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var username = ""
    @State private var password = ""
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                UserProfileView(authManager: authManager)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Login to MangaDex")
                            .font(.title)
                            .padding(.top, 40)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Personal Client Details")
                                .font(.headline)
                            
                            TextField("Client ID", text: $clientId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            SecureField("Client Secret", text: $clientSecret)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Link("Get API Client Credentials",
                                 destination: URL(string: "https://mangadex.org/settings")!)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Account Details")
                                .font(.headline)
                            
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        Button(action: login) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(isLoading || !isFormValid)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK") {}
                } message: {
                    Text(errorMessage)
                }
                .navigationBarHidden(true)
            }
        }
    }
    private var isFormValid: Bool {
            !username.isEmpty && !password.isEmpty &&
            !clientId.isEmpty && !clientSecret.isEmpty
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
        
        private func login() {
            isLoading = true
            let credentials = LoginCredentials(
                username: username,
                password: password,
                clientId: clientId,
                clientSecret: clientSecret
            )
            
            Task {
                do {
                    try await authManager.login(credentials: credentials)
                } catch let error as AuthenticationManager.AuthError {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "An unexpected error occurred"
                        showingError = true
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

struct UserProfileView: View {
    @ObservedObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome, \(authManager.currentUser ?? "User")!")
                .font(.title2)
            
            Button(action: { authManager.logout() }) {
                Text("Logout")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .navigationBarHidden(true)
    }
}

class FollowsManager: ObservableObject {
    @Published private(set) var followedManga: [String: Manga] = [:]
    @Published private(set) var latestChapters: [ChapterFeed] = []
    @Published private(set) var isSyncing = false
    private let authManager: AuthenticationManager
    private let defaults = UserDefaults.standard
    private let followsKey = "mangaFollows"
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        // Load local follows initially
        loadLocalFollows()
        // Then sync with server
        Task {
            await syncWithServer()
        }
    }
    
    func syncWithServer() async {
           guard authManager.isAuthenticated,
                 let token = authManager.keychainHelper.getAccessToken() else {
               print("Not authenticated, skipping server sync")
               return
           }
           
           await MainActor.run { isSyncing = true }
           
           do {
               // First, get all manga with reading status
               let statusUrl = URL(string: "https://api.mangadex.org/manga/status")!
               var statusRequest = URLRequest(url: statusUrl)
               statusRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
               
               print("Fetching manga reading status...")
               let (statusData, statusResponse) = try await URLSession.shared.data(for: statusRequest)
               
               guard let httpStatusResponse = statusResponse as? HTTPURLResponse,
                     httpStatusResponse.statusCode == 200 else {
                   print("Failed to fetch reading status")
                   throw AuthError.serverError("Failed to fetch reading status")
               }
               
               // Now get all followed manga regardless of status
               var allManga: [Manga] = []
               var offset = 0
               let limit = 100
               
               print("Fetching all followed manga...")
               while true {
                   var components = URLComponents(string: "https://api.mangadex.org/user/follows/manga")!
                   components.queryItems = [
                       URLQueryItem(name: "limit", value: "\(limit)"),
                       URLQueryItem(name: "offset", value: "\(offset)"),
                       URLQueryItem(name: "includes[]", value: "cover_art"),
                       // Include all content ratings
                       URLQueryItem(name: "contentRating[]", value: "safe"),
                       URLQueryItem(name: "contentRating[]", value: "suggestive"),
                       URLQueryItem(name: "contentRating[]", value: "erotica"),
                       URLQueryItem(name: "contentRating[]", value: "pornographic")
                   ]
                   
                   var request = URLRequest(url: components.url!)
                   request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                   
                   let (data, response) = try await URLSession.shared.data(for: request)
                   
                   guard let httpResponse = response as? HTTPURLResponse,
                         httpResponse.statusCode == 200 else {
                       throw AuthError.serverError("Failed to fetch followed manga")
                   }
                   
                   let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
                   let mangaResponse = try decoder.decode(MangaResponse.self, from: data)
                   
                   allManga.append(contentsOf: mangaResponse.data)
                   print("Fetched \(mangaResponse.data.count) manga in this batch")
                   
                   if mangaResponse.data.count < limit {
                       break
                   }
                   
                   offset += limit
               }
               
               print("Total manga fetched: \(allManga.count)")
               
               // Update our local state with all manga
               await MainActor.run {
                   self.followedManga = Dictionary(
                       uniqueKeysWithValues: allManga.map { ($0.id, $0) }
                   )
                   self.defaults.set(Array(self.followedManga.keys), forKey: self.followsKey)
                   self.isSyncing = false
               }
               
               // Load the feed to get latest chapters
               try await loadFollowedMangaFeed()
               
           } catch {
               print("Error during sync: \(error)")
               await MainActor.run { self.isSyncing = false }
           }
       }
    private func shouldRefreshToken(_ token: String) async throws -> Bool {
        let checkUrl = URL(string: "https://api.mangadex.org/auth/check")!
        var request = URLRequest(url: checkUrl)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode != 200
    }
    
    func loadFollowedMangaFeed() async throws {
        guard authManager.isAuthenticated,
              let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        var components = URLComponents(string: "https://api.mangadex.org/user/follows/manga/feed")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "translatedLanguage[]", value: "en"),
            URLQueryItem(name: "order[publishAt]", value: "desc"),
            URLQueryItem(name: "includes[]", value: "manga"),
            URLQueryItem(name: "includes[]", value: "scanlation_group"),
            URLQueryItem(name: "includes[]", value: "cover_art"),
            URLQueryItem(name: "contentRating[]", value: "safe"),
            URLQueryItem(name: "contentRating[]", value: "suggestive"),
            URLQueryItem(name: "contentRating[]", value: "erotica"),
            URLQueryItem(name: "contentRating[]", value: "pornographic")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to fetch manga feed")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let feedResponse = try decoder.decode(ChapterListResponse.self, from: data)
        
        let feeds = try await withThrowingTaskGroup(of: ChapterFeed?.self) { group in
            // Create an array to store our results
            var feedResults: [ChapterFeed] = []
            
            // Add each chapter processing task to the group
            for chapter in feedResponse.data {
                group.addTask {
                    // Find the manga relationship
                    guard let mangaRelation = chapter.relationships.first(where: { $0.type == "manga" }) else {
                        return nil
                    }
                    
                    // Find the cover art relationship if it exists
                    let coverRelation = chapter.relationships.first(where: { $0.type == "cover_art" })
                    let coverFileName = coverRelation?.attributes?.fileName
                    
                    // Create cover URL if we have a filename
                    let coverUrl: URL?
                    if let fileName = coverFileName {
                        coverUrl = URL(string: "https://uploads.mangadex.org/covers/\(mangaRelation.id)/\(fileName)")
                    } else {
                        coverUrl = nil
                    }
                    
                    // Get the scanlation group name
                    let scanlationGroup = chapter.relationships
                        .first(where: { $0.type == "scanlation_group" })?
                        .attributes?.name
                    
                    // Parse the date
                    let publishDate = DateFormatter.mangaDateFormatter.date(from: chapter.attributes.publishAt) ?? Date()
                    
                    // Fetch the manga details to get the title
                    let mangaDetails = try await self.fetchMangaDetails(id: mangaRelation.id)
                    let mangaTitle = mangaDetails.attributes.title["en"] ?? "Unknown"
                    
                    return ChapterFeed(
                        id: chapter.id,
                        mangaTitle: mangaTitle,
                        chapterNumber: chapter.attributes.chapter,
                        chapterTitle: chapter.attributes.title,
                        scanlationGroup: scanlationGroup,
                        publishedAt: publishDate,
                        manga: mangaDetails,
                        coverUrl: coverUrl
                    )
                }
            }
            
            // Collect all the results from the tasks
            for try await result in group {
                if let feed = result {
                    feedResults.append(feed)
                }
            }
            
            // Sort the results by publish date before returning
            return feedResults.sorted { $0.publishedAt > $1.publishedAt }
        }
        
        await MainActor.run {
            self.latestChapters = feeds
        }
    }
    
    
    
    // Add the missing fetchMangaDetails method
    private func fetchMangaDetails(id: String) async throws -> Manga {
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
        // Renamed the variable to avoid conflict
        let mangaResponse = try decoder.decode(SingleMangaResponse.self, from: data)
        return mangaResponse.data
    }
    
    
    private func loadLocalFollows() {
        if let followedIds = defaults.stringArray(forKey: followsKey) {
            // Load the basic IDs first for immediate display
            for id in followedIds {
                followedManga[id] = nil  // Placeholder until we get full manga data
            }
            
            // Then fetch full manga details in the background
            Task {
                for id in followedIds {
                    do {
                        let manga = try await fetchMangaDetails(id: id)
                        await MainActor.run {
                            self.followedManga[id] = manga
                        }
                    } catch {
                        print("Error loading local follow \(id): \(error)")
                    }
                }
            }
        }
    }
    // Response type matching MangaDex API format
    private struct MangaDexResponse: Decodable {
        let result: String // "ok" or "error"
        let errors: [MangaDexError]?
        
        struct MangaDexError: Decodable {
            let id: String
            let status: Int
            let title: String
            let detail: String
        }
    }
    
    // Check if following a specific manga
    func isFollowingManga(id: String) async throws -> Bool {
        guard authManager.isAuthenticated,
              let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        // Create request to check follow status
        let url = URL(string: "https://api.mangadex.org/user/follows/manga/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle response according to API documentation
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                // 200 response means the user follows this manga
                return true
            case 404:
                // 404 response means the user doesn't follow this manga
                return false
            default:
                // Handle unexpected status codes
                let decodedError = try? JSONDecoder().decode(MangaDexResponse.self, from: data)
                throw AuthError.serverError(decodedError?.errors?.first?.detail ?? "Unknown error")
            }
        }
        throw AuthError.networkError
    }
    
    // Follow a manga
    func followManga(id: String) async throws {
        guard authManager.isAuthenticated,
              let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        // Create request to follow manga
        let url = URL(string: "https://api.mangadex.org/manga/\(id)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle response according to API documentation
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                // Successfully followed
                let decodedResponse = try JSONDecoder().decode(MangaDexResponse.self, from: data)
                if decodedResponse.result == "ok" {
                    // Fetch the manga details to update local state
                    try await fetchMangaDetails(id: id)
                    return
                }
            case 404:
                throw AuthError.serverError("Manga not found")
            default:
                let decodedError = try? JSONDecoder().decode(MangaDexResponse.self, from: data)
                throw AuthError.serverError(decodedError?.errors?.first?.detail ?? "Failed to follow manga")
            }
        }
        throw AuthError.networkError
    }
    
    // Unfollow a manga
    func unfollowManga(id: String) async throws {
        guard authManager.isAuthenticated,
              let token = authManager.keychainHelper.getAccessToken() else {
            throw AuthError.tokenExpired
        }
        
        // Create request to unfollow manga
        let url = URL(string: "https://api.mangadex.org/manga/\(id)/follow")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle response according to API documentation
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                // Successfully unfollowed
                let decodedResponse = try JSONDecoder().decode(MangaDexResponse.self, from: data)
                if decodedResponse.result == "ok" {
                    // Update local state
                    await MainActor.run {
                        followedManga.removeValue(forKey: id)
                    }
                    return
                }
            case 404:
                throw AuthError.serverError("Manga not found")
            default:
                let decodedError = try? JSONDecoder().decode(MangaDexResponse.self, from: data)
                throw AuthError.serverError(decodedError?.errors?.first?.detail ?? "Failed to unfollow manga")
            }
        }
        throw AuthError.networkError
    }
    
    // Combined toggle function for convenience
    func toggleFollow(manga: Manga) async throws {
           guard authManager.isAuthenticated else {
               throw AuthError.tokenExpired
           }
           
           // Get initial token
           guard var token = authManager.keychainHelper.getAccessToken() else {
               throw AuthError.tokenExpired
           }
           
           // Verify token validity and refresh if needed
           do {
               let checkUrl = URL(string: "https://api.mangadex.org/auth/check")!
               var checkRequest = URLRequest(url: checkUrl)
               checkRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
               
               let (data, response) = try await URLSession.shared.data(for: checkRequest)
               
               if let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode != 200 {
                   // Token is invalid, perform refresh
                   try await authManager.refreshAccessToken()
                   
                   // Get the new token
                   guard let newToken = authManager.keychainHelper.getAccessToken() else {
                       throw AuthError.tokenExpired
                   }
                   token = newToken
               }
           } catch {
               // Handle any network or refresh errors
               throw AuthError.tokenExpired
           }
           
           // Proceed with the follow/unfollow operation using the valid token
           let isCurrentlyFollowing = try await isFollowingManga(id: manga.id)
           let url = URL(string: "https://api.mangadex.org/manga/\(manga.id)/follow")!
           
           var request = URLRequest(url: url)
           request.httpMethod = isCurrentlyFollowing ? "DELETE" : "POST"
           request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           
           let (data, response) = try await URLSession.shared.data(for: request)
           
           guard let httpResponse = response as? HTTPURLResponse else {
               throw AuthError.networkError
           }
           
           switch httpResponse.statusCode {
           case 200:
               // Update local state after successful API call
               await MainActor.run {
                   if isCurrentlyFollowing {
                       self.followedManga.removeValue(forKey: manga.id)
                   } else {
                       self.followedManga[manga.id] = manga
                   }
               }
               // Refresh the feed
               try await loadFollowedMangaFeed()
               
           case 401:
               throw AuthError.tokenExpired
           case 404:
               throw AuthError.serverError("Manga not found")
           default:
               if let errorString = String(data: data, encoding: .utf8) {
                   print("Error response: \(errorString)")
               }
               throw AuthError.serverError("Failed with status code: \(httpResponse.statusCode)")
           }
       }
    }

struct FollowButton: View {
    @ObservedObject var followsManager: FollowsManager
    let manga: Manga
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isFollowing = false
    
    var body: some View {
        Button(action: handleFollow) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: isFollowing ? "heart.fill" : "heart")
                }
                Text(isFollowing ? "Following" : "Follow")
            }
            .foregroundColor(isFollowing ? .red : .blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 2)
        }
        .disabled(isLoading)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Check if manga is in followedManga dictionary
            isFollowing = followsManager.followedManga[manga.id] != nil
        }
    }
    
    private func handleFollow() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await followsManager.toggleFollow(manga: manga)
                await MainActor.run {
                    isFollowing.toggle()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
