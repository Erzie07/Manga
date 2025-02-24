import Foundation
import Combine

@MainActor
class ChapterListViewModel: ObservableObject {
    enum SortOrder: String, CaseIterable {
        case asc = "asc"
        case desc = "desc"
    }
    
    @Published var chapters: [Chapter] = []
    @Published private(set) var isLoading = true
    @Published var hasMoreChapters = true
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .desc
    @Published var isDirectSearchActive = false
    @Published private(set) var totalChapters: Int = 0
    
    private var allChapters: [Chapter] = []
    private var chaptersDictionary: [String: Chapter] = [:]
    private var currentOffset = 0
    private let limit = 200
    private let mangaId: String
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var isInitialLoad = true
    
    init(mangaId: String) {
        self.mangaId = mangaId
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        $searchText
            .removeDuplicates()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                guard let self = self else { return }
                self.filterLocalChapters(searchText)
            }
            .store(in: &cancellables)
        
        $sortOrder
            .removeDuplicates()
            .sink { [weak self] newOrder in
                guard let self = self else { return }
                self.sortChapters(order: newOrder)
            }
            .store(in: &cancellables)
    }
     
    
    // New method to handle sorting without full reload
    private func sortChapters(order: SortOrder) {
        sortMatchedChapters(&allChapters, order: order)
        
        // Then sort the filtered chapters
        var currentChapters = chapters
        sortMatchedChapters(&currentChapters, order: order)
        chapters = currentChapters
    }
    
    private func resetAndReload() {
          Task {
              await resetAndLoadChapters()
          }
      }
    
    private func isExactChapterSearch(_ search: String) -> Bool {
        let chapterPattern = "^(\\d+(\\.\\d+)?|oneshot)$"
        return search.lowercased().range(of: chapterPattern, options: .regularExpression) != nil
    }
    
    private func filterLocalChapters(_ searchText: String) {
        
        if searchText.isEmpty {
            return
        }
        
        let searchLower = searchText.lowercased()
        
        // Filter chapters based on search criteria
        var matchedChapters = allChapters.filter { chapter in
            let chapterNumber = chapter.attributes.chapter ?? ""
            let titleMatch = chapter.attributes.title?.lowercased().contains(searchLower) ?? false
            let chapterMatch = chapterNumber.lowercased().contains(searchLower)
            let groupMatch = chapter.relationships.first(where: { $0.type == "scanlation_group" })?
                .attributes?.name?.lowercased().contains(searchLower) ?? false
            
            let isMatch = titleMatch || chapterMatch || groupMatch
            if isMatch {
                print("✅ Match found - Chapter:", chapterNumber)
            }
            return isMatch
        }
        
        // Sort based on the current sort order
        sortMatchedChapters(&matchedChapters, order: sortOrder)
        
        chapters = matchedChapters
    }

    private func sortMatchedChapters(_ chapters: inout [Chapter], order: SortOrder) {
        chapters.sort { a, b in
            guard let numA = Double(a.attributes.chapter ?? ""),
                  let numB = Double(b.attributes.chapter ?? "") else {
                return false
            }
            return order == .asc ? numA < numB : numA > numB
        }
    }

    
    func resetAndLoadChapters() async {
        // Cancel any ongoing load task
        loadTask?.cancel()
        
        // Store current sort order
        let currentSortOrder = sortOrder
        // Create new load task
        loadTask = Task {
            isLoading = true
            isDirectSearchActive = false
            allChapters = []
            chapters = []
            chaptersDictionary = [:]
            currentOffset = 0
            hasMoreChapters = true
            
            // Ensure sort order is maintained
            sortOrder = currentSortOrder
            
            // Fetch initial metadata to get total count
            do {
                let (total, initialChapters) = try await fetchChaptersPage()
                totalChapters = total
                
                // Process initial chapters
                guard !Task.isCancelled else { return }
                processNewChapters(initialChapters)
                
                // If we have a lot of chapters, continue loading in background
                if hasMoreChapters {
                    await loadRemainingChaptersInBackground()
                }
            } catch {
                print("❌ Error in initial chapter load:", error)
                isLoading = false
            }
        }
        
        await loadTask?.value
    }

    
    private func processNewChapters(_ newChapters: [Chapter]) {
        let filteredChapters = newChapters.filter { $0.attributes.chapter != nil }
        
        filteredChapters.forEach { chapter in
            if let chapterKey = chapter.attributes.chapter?.lowercased() {
                chaptersDictionary[chapterKey] = chapter
            }
        }
        
        allChapters.append(contentsOf: filteredChapters)
        
        // Sort according to current sort order
        allChapters.sort { a, b in
            guard let chapterA = Double(a.attributes.chapter ?? ""),
                  let chapterB = Double(b.attributes.chapter ?? "") else {
                return false
            }
            return sortOrder == .asc ? chapterA < chapterB : chapterA > chapterB
        }
        
        // Update the published chapters array
        if searchText.isEmpty {
            chapters = allChapters
        } else {
            filterLocalChapters(searchText)
        }
    }
    
    func loadChapters() async {
        // Don't load more chapters if we're in direct search mode
        guard hasMoreChapters && !isDirectSearchActive else {
            isLoading = false  // Make sure to reset loading state if we're not loading
            return
        }
        
        do {
            var components = URLComponents(string: "https://api.mangadex.org/manga/\(mangaId)/feed")!
            let queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(currentOffset)"),
                URLQueryItem(name: "translatedLanguage[]", value: "en"),
                URLQueryItem(name: "order[chapter]", value: sortOrder.rawValue),
                URLQueryItem(name: "includes[]", value: "scanlation_group")
            ]
            
            components.queryItems = queryItems
            
            guard let url = components.url else {
                print("Error: Could not construct URL")
                isLoading = false
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(ChapterListResponse.self, from: data)
            
            let newChapters = response.data.filter { $0.attributes.chapter != nil }
            
            newChapters.forEach { chapter in
                if let chapterKey = chapter.attributes.chapter?.lowercased() {
                    chaptersDictionary[chapterKey] = chapter
                }
            }
            
            allChapters.append(contentsOf: newChapters)
            currentOffset += newChapters.count
            hasMoreChapters = response.total > allChapters.count
            
            if searchText.isEmpty {
                chapters = allChapters
            } else {
                filterLocalChapters(searchText)
            }
            
        } catch {
            print("Error loading chapters:", error)
        }
        
        isLoading = false
    }
    
    private func fetchChaptersPage() async throws -> (total: Int, chapters: [Chapter]) {
        var components = URLComponents(string: "https://api.mangadex.org/manga/\(mangaId)/feed")!
        let queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(currentOffset)"),
            URLQueryItem(name: "translatedLanguage[]", value: "en"),
            URLQueryItem(name: "order[chapter]", value: sortOrder.rawValue),
            URLQueryItem(name: "includes[]", value: "scanlation_group")
        ]
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ChapterListResponse.self, from: data)
        
        return (response.total, response.data)
    }
    
    private func loadRemainingChaptersInBackground() async {
        while hasMoreChapters && !Task.isCancelled {
            do {
                currentOffset += limit
                let (total, newChapters) = try await fetchChaptersPage()
                
                guard !Task.isCancelled else { return }
                
                processNewChapters(newChapters)
                hasMoreChapters = currentOffset < total
                
                // Small delay to prevent API rate limiting
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            } catch {
                print("Error loading additional chapters:", error)
                break
            }
        }
        
        isLoading = false
    }
}
