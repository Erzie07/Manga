import Foundation
import Combine

@MainActor
class ChapterListViewModel: ObservableObject {
    enum SortOrder: String, CaseIterable {
        case asc = "asc"
        case desc = "desc"
    }
    
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var hasMoreChapters = true
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .desc
    
    private var allChapters: [Chapter] = []
    private var currentOffset = 0
    private let limit = 20
    private let mangaId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(mangaId: String) {
        self.mangaId = mangaId
        
        // Debounce search input
        $searchText
            .removeDuplicates()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.filterChapters()
            }
            .store(in: &cancellables)
        
        // React to sort changes
        $sortOrder
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.resetAndReload()
            }
            .store(in: &cancellables)
    }
    
    private func resetAndReload() {
        Task {
            await resetAndLoadChapters()
        }
    }
    
    private func filterChapters() {
        if searchText.isEmpty {
            chapters = allChapters
        } else {
            chapters = allChapters.filter { chapter in
                let searchLower = searchText.lowercased()
                return chapter.attributes.title?.lowercased().contains(searchLower) ?? false ||
                       chapter.attributes.chapter?.lowercased().contains(searchLower) ?? false ||
                (chapter.relationships.first(where: { $0.type == "scanlation_group" })?.attributes?.name?.lowercased().contains(searchLower) ?? false)
            }
        }
    }
    
    func resetAndLoadChapters() async {
        allChapters = []
        chapters = []
        currentOffset = 0
        hasMoreChapters = true
        await loadChapters()
    }
    
    func loadChapters() async {
        guard hasMoreChapters && !isLoading else { return }
        
        isLoading = true
        
        do {
            var components = URLComponents(string: "https://api.mangadex.org/manga/\(mangaId)/feed")!
            let queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(currentOffset)"),
                URLQueryItem(name: "translatedLanguage[]", value: "en"),
                URLQueryItem(name: "order[chapter]", value: sortOrder.rawValue),
                URLQueryItem(name: "includes[]", value: "scanlationgroup"),
                URLQueryItem(name: "contentRating[]", value: "safe"),
                URLQueryItem(name: "contentRating[]", value: "suggestive"),
                URLQueryItem(name: "contentRating[]", value: "erotica"),
                URLQueryItem(name: "contentRating[]", value: "pornographic")
            ]
            
            components.queryItems = queryItems
            
            guard let url = components.url else {
                print("Error: Could not construct URL")
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(ChapterListResponse.self, from: data)
            
            let newChapters = response.data.filter { $0.attributes.chapter != nil }
            
            allChapters.append(contentsOf: newChapters)
            currentOffset += newChapters.count
            hasMoreChapters = response.total > allChapters.count
            filterChapters()
            isLoading = false
            
        } catch {
            print("Error loading chapters:", error)
            isLoading = false
        }
    }
}
