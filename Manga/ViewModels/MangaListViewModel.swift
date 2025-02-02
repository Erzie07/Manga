import Foundation

class MangaListViewModel: ObservableObject {
    @Published var mangas: [Manga] = []
    @Published var tags: [Tag] = []
    @Published var filter = MangaFilter()
    @Published var isLoading = false
    private var currentPage = 0
    private let itemsPerPage = 20
    private var searchTask: Task<Void, Never>?
    private let searchDelay: TimeInterval = 0.5 // Delay in seconds
    
    // Add a method to handle search updates with debouncing
    func handleSearchUpdate() {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task with delay
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(searchDelay * 1_000_000_000))
            
            // Check if task was cancelled
            if !Task.isCancelled {
                await reloadData()
            }
        }
    }
}

extension MangaListViewModel {
    func initializeData() async {
        do {
            let response: TagResponse = try await MangaDexAPI.fetch(.tags)
            await MainActor.run {
                self.tags = response.data
            }
            await loadNextPage()
        } catch {
            print("Error loading initial data:", error)
        }
    }
}


extension MangaListViewModel {
    func loadNextPage() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        // Base parameters
        var baseParams = [
            "limit": String(itemsPerPage),
            "offset": String(currentPage * itemsPerPage),
            "includes[]": "cover_art",
            "availableTranslatedLanguage[]": "en"
        ]
        
        // Add title search if present
        if !filter.titleSearch.isEmpty {
            // Using proper title parameter
            baseParams["title"] = filter.titleSearch
        }
        
        // Add author/artist search if present
        if !filter.authorSearch.isEmpty || !filter.artistSearch.isEmpty {
            let searchTerm = !filter.authorSearch.isEmpty ? filter.authorSearch : filter.artistSearch
            // Add author/artist parameter
            baseParams["authorOrArtist"] = searchTerm
            // Include author data in response
            baseParams["includes[]"] = "author,artist,cover_art"
        }
        
        // Add content rating if present
        if let contentRating = filter.contentRating {
            baseParams["contentRating[]"] = contentRating.rawValue
        }
        
        // Add sorting parameters
        let sortParams = filter.sortOption.apiParameter
        baseParams.merge(sortParams) { current, _ in current }
        
        // Create URL with base parameters
        var components = URLComponents(string: "\(MangaDexAPI.baseURL)/manga")!
        var queryItems = baseParams.flatMap { key, value -> [URLQueryItem] in
            if key.hasSuffix("[]") {
                // Handle array parameters
                return value.split(separator: ",").map {
                    URLQueryItem(name: key, value: String($0).trimmingCharacters(in: .whitespaces))
                }
            } else {
                return [URLQueryItem(name: key, value: value)]
            }
        }
        
        // Add tag inclusion mode
        queryItems.append(URLQueryItem(name: "includedTagsMode",
                                     value: filter.tagInclusionMode == .and ? "AND" : "OR"))
        
        // Add included tags
        for tagId in filter.selectedTags {
            queryItems.append(URLQueryItem(name: "includedTags[]", value: tagId))
        }
        
        // Add excluded tags
        for tagId in filter.excludedTags {
            queryItems.append(URLQueryItem(name: "excludedTags[]", value: tagId))
        }
        
        // Add demographic if present
        if let demographic = filter.selectedDemographic {
            queryItems.append(URLQueryItem(name: "publicationDemographic[]",
                                         value: demographic.rawValue))
        }
        
        // Add year if present
        if let year = filter.publicationYear {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("Error: Could not construct URL")
            return
        }
        
        print("\nFinal URL:")
        print(url.absoluteString)
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("\nAPI Response:")
                print(jsonString)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let mangaResponse = try decoder.decode(MangaResponse.self, from: data)
            
            await MainActor.run {
                if currentPage == 0 {
                    self.mangas = mangaResponse.data
                } else {
                    self.mangas.append(contentsOf: mangaResponse.data)
                }
                self.currentPage += 1
                self.isLoading = false
            }
            
        } catch {
            print("\nError loading manga:")
            print(error)
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    @MainActor
    func reloadData() async {
        currentPage = 0
        mangas = []
        await loadNextPage()
    }
}
