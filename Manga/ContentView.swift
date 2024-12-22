import SwiftUI

// MangaDexAPI.swift
import Foundation

struct CoverArt: Decodable {
    let id: String
    let type: String
    let attributes: CoverAttributes
}

struct CoverAttributes: Decodable {
    let fileName: String
}

struct TagResponse: Decodable {
    let data: [Tag]
    let total: Int
}

struct ChapterData: Decodable {
    let hash: String
    let data: [String]
    let dataSaver: [String]
}

struct ChapterPages: Decodable {
    let result: String
    let baseUrl: String
    let chapter: ChapterData
}

struct ChapterListResponse: Codable {
    let data: [Chapter]
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case data
        case total
    }
}

struct Chapter: Identifiable, Codable {
    let id: String
    let type: String
    let attributes: ChapterAttributes
    let relationships: [Relationship]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case attributes
        case relationships
    }
}

enum TagInclusionMode: String, CaseIterable {
    case and = "And"
    case or = "Or"
}

struct ChapterAttributes: Codable {
    let volume: String?
    let chapter: String?
    let title: String?
    let translatedLanguage: String
    let externalUrl: String?
    let publishAt: String
    let readableAt: String
    let createdAt: String
    let updatedAt: String
    let pages: Int
    let version: Int
    
    enum CodingKeys: String, CodingKey {
        case volume
        case chapter
        case title
        case translatedLanguage
        case externalUrl
        case publishAt
        case readableAt
        case createdAt
        case updatedAt
        case pages
        case version
    }
}

enum ContentRating: String, CaseIterable {
    case safe = "safe"
    case suggestive = "suggestive"
    case erotica = "erotica"
    case pornographic = "pornographic"
    
    var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .suggestive: return "Suggestive"
        case .erotica: return "Erotica"
        case .pornographic: return "Pornographic"
        }
    }
}

// Update MangaListViewModel SortOption enum
extension MangaListViewModel {
    enum SortOption: String, CaseIterable {
        case bestMatch = "relevance"
        case latestUpload = "latestUploadedChapter"
        case oldestUpload = "oldestUploadedChapter"
        case titleAsc = "titleAsc"
        case titleDesc = "titleDesc"
        case highestRating = "rating"
        case lowestRating = "ratingAsc"
        case followedCount = "followedCount"
        case fewestFollows = "followedCountAsc"
        case recentlyAdded = "createdAt"
        case oldestAdded = "createdAtAsc"
        case yearAsc = "year"
        case yearDesc = "yearDesc"
        
        var displayName: String {
            switch self {
            case .bestMatch: return "Best Match"
            case .latestUpload: return "Latest Upload"
            case .oldestUpload: return "Oldest Upload"
            case .titleAsc: return "Title Ascending"
            case .titleDesc: return "Title Descending"
            case .highestRating: return "Highest Rating"
            case .lowestRating: return "Lowest Rating"
            case .followedCount: return "Most Follows"
            case .fewestFollows: return "Fewest Follows"
            case .recentlyAdded: return "Recently Added"
            case .oldestAdded: return "Oldest Added"
            case .yearAsc: return "Year Ascending"
            case .yearDesc: return "Year Descending"
            }
        }
        
        var apiParameter: [String: String] {
            switch self {
            case .bestMatch:
                return ["order[relevance]": "desc"]
            case .latestUpload:
                return ["order[latestUploadedChapter]": "desc"]
            case .oldestUpload:
                return ["order[latestUploadedChapter]": "asc"]
            case .titleAsc:
                return ["order[title]": "asc"]
            case .titleDesc:
                return ["order[title]": "desc"]
            case .highestRating:
                return ["order[rating]": "desc"]
            case .lowestRating:
                return ["order[rating]": "asc"]
            case .followedCount:
                return ["order[followedCount]": "desc"]
            case .fewestFollows:
                return ["order[followedCount]": "asc"]
            case .recentlyAdded:
                return ["order[createdAt]": "desc"]
            case .oldestAdded:
                return ["order[createdAt]": "asc"]
            case .yearAsc:
                return ["order[year]": "asc"]
            case .yearDesc:
                return ["order[year]": "desc"]
            }
        }
    }
}

struct Relationship: Codable {
    let id: String
    let type: String
    let attributes: RelationshipAttributes?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case attributes
    }
}

struct RelationshipAttributes: Codable {
    // Common attributes
    let name: String?
    // Cover-specific attributes
    let fileName: String?
    // Group-specific attributes
    let volume: String?
    // Add more attributes as needed for different relationship types
    
    enum CodingKeys: String, CodingKey {
        case name
        case fileName
        case volume
    }
}

// Helper extension to make working with relationships easier
extension Relationship {
    var isCover: Bool {
        type == "cover_art"
    }
    
    var isAuthor: Bool {
        type == "author"
    }
    
    var isScanlationGroup: Bool {
        type == "scanlation_group"
    }
}


enum PublicationDemographic: String, CaseIterable {
    case shounen = "shounen"
    case shoujo = "shoujo"
    case seinen = "seinen"
    case josei = "josei"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .shounen: return "Shounen"
        case .shoujo: return "Shoujo"
        case .seinen: return "Seinen"
        case .josei: return "Josei"
        case .none: return "None"
        }
    }
}

struct MangaFilter {
    var selectedDemographic: PublicationDemographic?
    var publicationYear: Int?
    var selectedTags: Set<String> = []
    var excludedTags: Set<String> = []
    var tagInclusionMode: TagInclusionMode = .and
    var contentRating: ContentRating? = .safe
    var sortOption: MangaListViewModel.SortOption = .latestUpload
    // Add new search fields
    var titleSearch: String = ""
    var authorSearch: String = ""
    var artistSearch: String = ""
}


class MangaDexAPI {
    static let baseURL = "https://api.mangadex.org"
    static let baseImageURL = "https://uploads.mangadex.org"
    
    enum Endpoint {
        case manga(parameters: [String: String])
        case mangaDetails(id: String)
        case chapters(mangaId: String, parameters: [String: String])
        case cover(mangaId: String)
        case tags
        case chapterPages(chapterId: String)
        
        var url: URL {
            switch self {
            case .manga(let parameters):
                var components = URLComponents(string: "\(MangaDexAPI.baseURL)/manga")!
                components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
                return components.url!
            case .mangaDetails(let id):
                return URL(string: "\(MangaDexAPI.baseURL)/manga/\(id)?includes[]=cover_art")!
            case .chapters(let mangaId, let parameters):
                var components = URLComponents(string: "\(MangaDexAPI.baseURL)/manga/\(mangaId)/feed")!
                var queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
                queryItems.append(URLQueryItem(name: "includes[]", value: "scanlation_group"))
                components.queryItems = queryItems
                return components.url!
            case .cover(let mangaId):
                return URL(string: "\(MangaDexAPI.baseURL)/cover/\(mangaId)")!
            case .tags:
                return URL(string: "\(MangaDexAPI.baseURL)/manga/tag")!
            case .chapterPages(let chapterId):
                return URL(string: "\(MangaDexAPI.baseURL)/at-home/server/\(chapterId)")!
            }
        }
    }
    
    static func getCoverImageURL(mangaId: String, filename: String) -> URL {
        return URL(string: "\(baseImageURL)/covers/\(mangaId)/\(filename)")!
    }
    
    enum APIError: Error {
        case invalidResponse
        case httpError(statusCode: Int)
        case decodingError
    }
}

// Models.swift
struct MangaResponse: Decodable {
    let data: [Manga]
    let total: Int
}

struct Manga: Identifiable, Decodable {
    let id: String
    let attributes: MangaAttributes
    let relationships: [Relationship]
}

struct MangaAttributes: Decodable {
    let title: [String: String]
    let description: [String: String]
    let year: Int?
    let status: String
    let tags: [Tag]
    let updatedAt: String
    let rating: Double?
}

struct Tag: Identifiable, Decodable {
    let id: String
    let attributes: TagAttributes
    
    var category: TagCategory {
        switch attributes.group {
        case "format": return .format
        case "genre": return .genre
        case "theme": return .theme
        case "content": return .content
        default: return .theme
        }
    }
}


struct TagAttributes: Decodable {
    let name: [String: String]
    let group: String
}

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: MangaListViewModel
    @ObservedObject var authManager: AuthenticationManager
    @StateObject var libraryManager: LibraryManager
    @State private var searchText = ""
    @State private var showingFilters = false
    
    init(viewModel: MangaListViewModel,
         authManager: AuthenticationManager) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.authManager = authManager
        _libraryManager = StateObject(wrappedValue: LibraryManager(authManager: authManager))
    }
    
    var body: some View {
        TabView {
            // Browse Tab
            NavigationView {
                VStack {
                    ClearableTextField(
                        placeholder: "Search manga...",
                        text: $searchText,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.filter.titleSearch = searchText
                                Task {
                                    await viewModel.reloadData()
                                }
                            }
                        }
                    )
                    .padding()
                    
                    List {
                        ForEach(viewModel.mangas) { manga in
                            NavigationLink(destination: MangaDetailView(manga: manga, libraryManager: libraryManager)) {
                                MangaRowView(manga: manga)
                            }
                        }
                        
                        if !viewModel.mangas.isEmpty {
                            ProgressView()
                                .onAppear {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .navigationTitle("Browse")
                .browseToolbar(showingFilters: $showingFilters)
                .sheet(isPresented: $showingFilters) {
                    FilterView(viewModel: viewModel)
                }
                .task {
                    await viewModel.initializeData()
                }
                .refreshable {
                    await viewModel.reloadData()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Browse", systemImage: "book")
            }
            
            // Library Tab
            NavigationView {
                LibraryView(libraryManager: libraryManager, authManager: authManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            
            // Login Tab
            NavigationView {
                LoginView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
        }
    }
}

struct BrowseToolbarModifier: ViewModifier {
    @Binding var showingFilters: Bool
    
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                        .accessibilityLabel("Filter")
                }
            }
        }
    }
}

extension View {
    func browseToolbar(showingFilters: Binding<Bool>) -> some View {
        self.modifier(BrowseToolbarModifier(showingFilters: showingFilters))
    }
}

// MangaListViewModel.swift
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
// Update Tag model to include proper debugging information
extension Tag: CustomStringConvertible {
    var description: String {
        return "Tag(id: \(id), name: \(attributes.name["en"] ?? "unknown"))"
    }
}
struct ClearableTextField: View {
    let placeholder: String
    @Binding var text: String
    let onEditingChanged: (Bool) -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onEditingChanged(false)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
struct FlowLayout: View {
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let content: [AnyView]
    
    @State private var totalHeight: CGFloat = 0
    
    init<Data: RandomAccessCollection, Content: View>(
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 16,
        data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Data.Element: Identifiable {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.content = data.map { AnyView(content($0)) }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var x: CGFloat = horizontalPadding
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(content.enumerated()), id: \.offset) { index, view in
                view
                    .alignmentGuide(.leading) { dimensions in
                        let width = dimensions.width
                        let result: CGFloat
                        
                        if (x + width + horizontalPadding > geometry.size.width) {
                            x = horizontalPadding
                            y += maxHeight + spacing
                            maxHeight = 0
                        }
                        
                        result = x
                        x += width + spacing
                        maxHeight = max(maxHeight, dimensions.height)
                        
                        if index == content.count - 1 {
                            DispatchQueue.main.async {
                                self.totalHeight = y + maxHeight
                            }
                        }
                        
                        return -result
                    }
                    .alignmentGuide(.top) { _ in
                        -y
                    }
            }
        }
    }
}

class TagFilterViewController: UIViewController {
    private var viewModel: MangaListViewModel
    private var collectionViews: [TagCategory: UICollectionView] = [:]
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(viewModel: MangaListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Inclusion Mode Section
        let modeStack = UIStackView()
        modeStack.axis = .horizontal
        modeStack.spacing = 8
        modeStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        modeStack.isLayoutMarginsRelativeArrangement = true
        
        let modeLabel = UILabel()
        modeLabel.text = "Inclusion mode"
        modeLabel.textColor = .secondaryLabel
        
        let segmentedControl = UISegmentedControl(items: TagInclusionMode.allCases.map { $0.rawValue })
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(inclusionModeChanged), for: .valueChanged)
        
        modeStack.addArrangedSubview(modeLabel)
        modeStack.addArrangedSubview(segmentedControl)
        containerStack.addArrangedSubview(modeStack)
        
        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = "Click once to include, twice to exclude, third time to clear"
        instructionLabel.font = .preferredFont(forTextStyle: .caption1)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.numberOfLines = 0
        instructionLabel.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerStack.addArrangedSubview(instructionLabel)
        
        // Tag Categories
        let tagStack = UIStackView()
        tagStack.axis = .vertical
        tagStack.spacing = 12
        
        for category in TagCategory.allCases {
            let categoryStack = UIStackView()
            categoryStack.axis = .vertical
            categoryStack.spacing = 8
            
            let titleLabel = UILabel()
            titleLabel.text = category.rawValue
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            categoryStack.addArrangedSubview(titleLabel)
            
            let layout = TagFlowLayout()
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.backgroundColor = .clear
            collectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.isScrollEnabled = false
            
            // Fixed height constraint based on content
            let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            
            categoryStack.addArrangedSubview(collectionView)
            collectionViews[category] = collectionView
            
            if category != .content {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                categoryStack.addArrangedSubview(separator)
            }
            
            tagStack.addArrangedSubview(categoryStack)
        }
        
        containerStack.addArrangedSubview(tagStack)
    }
    
    @objc private func inclusionModeChanged(_ sender: UISegmentedControl) {
        viewModel.filter.tagInclusionMode = TagInclusionMode.allCases[sender.selectedSegmentIndex]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeights()
    }
    
    private func updateCollectionViewHeights() {
        for (_, collectionView) in collectionViews {
            collectionView.layoutIfNeeded()
            let height = collectionView.collectionViewLayout.collectionViewContentSize.height
            if let constraint = collectionView.constraints.first(where: { $0.firstAttribute == .height }) {
                constraint.constant = height
            }
        }
    }
}

class TagFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        var currentRowY: CGFloat = -1
        var currentRowAttributes: [UICollectionViewLayoutAttributes] = []
        
        for attribute in attributes {
            if attribute.frame.minY != currentRowY {
                currentRowY = attribute.frame.minY
                currentRowAttributes.removeAll()
            }
            currentRowAttributes.append(attribute)
        }
        
        return attributes
    }
}

class TagCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 32)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        return layoutAttributes
    }
    
    func configure(with tag: Tag, isIncluded: Bool, isExcluded: Bool) {
        label.text = tag.attributes.name["en"]
        
        if isIncluded {
            contentView.backgroundColor = .systemBlue
            label.textColor = .white
            contentView.layer.borderColor = UIColor.clear.cgColor
        } else if isExcluded {
            contentView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            label.textColor = .label
            contentView.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            contentView.backgroundColor = .clear
            label.textColor = .label
            contentView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        }
    }
}

extension TagFilterViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return 0 }
        return viewModel.tags.filter { $0.category == category }.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return cell }
        
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        cell.configure(
            with: tag,
            isIncluded: viewModel.filter.selectedTags.contains(tag.id),
            isExcluded: viewModel.filter.excludedTags.contains(tag.id)
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return }
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        if viewModel.filter.selectedTags.contains(tag.id) {
            viewModel.filter.selectedTags.remove(tag.id)
            viewModel.filter.excludedTags.insert(tag.id)
        } else if viewModel.filter.excludedTags.contains(tag.id) {
            viewModel.filter.excludedTags.remove(tag.id)
        } else {
            viewModel.filter.selectedTags.insert(tag.id)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return .zero }
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.text = tag.attributes.name["en"]
        
        let size = label.sizeThatFits(.zero)
        return CGSize(width: size.width + 24, height: 32)
    }
}
enum TagCategory: String, CaseIterable {
    case format = "Format"
    case genre = "Genre"
    case theme = "Theme"
    case content = "Content"
    
    var displayOrder: Int {
        switch self {
        case .format: return 0
        case .genre: return 1
        case .theme: return 2
        case .content: return 3
        }
    }
}

extension TagCategory: Comparable {
    static func < (lhs: TagCategory, rhs: TagCategory) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}

struct TagFilterView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MangaListViewModel
    
    func makeUIViewController(context: Context) -> TagFilterViewController {
        return TagFilterViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: TagFilterViewController, context: Context) {
        // Update if needed
    }
}



// MangaDetailView.swift
struct MangaDetailView: View {
    let manga: Manga
    @ObservedObject var libraryManager: LibraryManager
    @StateObject private var viewModel = ChapterListViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private var formattedTags: [String] {
        manga.attributes.tags
            .filter { $0.attributes.group == "genre" }
            .compactMap { $0.attributes.name["en"] }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover and Title Section
                HStack(alignment: .top, spacing: 16) {
                    CoverImageView(manga: manga, width: 120, height: 180)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(manga.attributes.title["en"] ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let rating = manga.attributes.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                        }
                        
                        Text("Status: \(manga.attributes.status.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let year = manga.attributes.year {
                            Text("Year: \(year)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        LibraryButton(libraryManager: libraryManager, manga: manga)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                // Tags Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8, data: formattedTags.indices.map { TagItem(id: formattedTags[$0], text: formattedTags[$0]) }) { item in
                        Text(item.text)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.horizontal)
                
                // Description Section
                if let description = manga.attributes.description["en"], !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                }
                
                // Chapters Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chapters")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.chapters.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.chapters.isEmpty {
                        Text("No chapters available")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.secondary)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.chapters) { chapter in
                                NavigationLink(destination: PagedChapterReaderView(chapter: chapter)) {
                                    ChapterRowView(chapter: chapter)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                }
                                Divider()
                                    .padding(.horizontal)
                            }
                            
                            if viewModel.hasMoreChapters {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await viewModel.loadChapters(mangaId: manga.id)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.resetAndLoadChapters(mangaId: manga.id)
        }
        .refreshable {
            await viewModel.resetAndLoadChapters(mangaId: manga.id)
        }
    }
}


struct ChapterResponse: Decodable {
    let data: [Chapter]
    let total: Int
    let limit: Int
    let offset: Int
}

struct ChapterServerResponse: Codable {
    let baseUrl: String
    let chapter: ChapterData
    
    struct ChapterData: Codable {
        let hash: String
        let data: [String]
        let dataSaver: [String]
        
        enum CodingKeys: String, CodingKey {
            case hash
            case data
            case dataSaver = "dataSaver"
        }
    }
}

@MainActor
class ChapterListViewModel: ObservableObject {
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var hasMoreChapters = true
    private var currentOffset = 0
    private let limit = 20
    
    func resetAndLoadChapters(mangaId: String) async {
        chapters = []
        currentOffset = 0
        hasMoreChapters = true
        await loadChapters(mangaId: mangaId)
    }
    
    func loadChapters(mangaId: String) async {
        guard hasMoreChapters && !isLoading else { return }
        
        isLoading = true
        
        do {
            var components = URLComponents(string: "https://api.mangadex.org/manga/\(mangaId)/feed")!
            var queryItems = [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(currentOffset)"),
                URLQueryItem(name: "translatedLanguage[]", value: "en"),
                URLQueryItem(name: "order[chapter]", value: "desc"),
                URLQueryItem(name: "includes[]", value: "scanlation_group"),
                // Add content ratings to include all possible ratings
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
            
            print("Chapter Feed URL:", url.absoluteString)
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Chapter Response:", jsonString)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(ChapterListResponse.self, from: data)
            
            let newChapters = response.data.filter { chapter in
                guard let _ = chapter.attributes.chapter else { return false }
                return true
            }
            
            self.chapters.append(contentsOf: newChapters)
            self.currentOffset += newChapters.count
            self.hasMoreChapters = response.total > self.chapters.count
            self.isLoading = false
            
        } catch {
            print("Error loading chapters:", error)
            self.isLoading = false
        }
    }
}

// Supporting Views
struct MangaRowView: View {
    let manga: Manga
    
    var body: some View {
        HStack {
            CoverImageView(manga: manga, width: 90, height: 120)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.attributes.title["en"] ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                Text(manga.attributes.updatedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let year = manga.attributes.year {
                    Text("Year: \(year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
        }
    }
}

struct ChapterRowView: View {
    let chapter: Chapter
    
    private var chapterTitle: String {
        if let title = chapter.attributes.title, !title.isEmpty {
            return title
        }
        return "Chapter \(chapter.attributes.chapter ?? "N/A")"
    }
    
    private var chapterSubtitle: String? {
        let components = [
            chapter.attributes.volume.map { "Vol. \($0)" },
            chapter.attributes.chapter.map { "Ch. \($0)" }
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
    
    private var scanlationGroup: String? {
        chapter.relationships
            .first(where: { $0.type == "scanlation_group" })?
            .attributes?.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapterTitle)
                .font(.body)
                .foregroundColor(.primary)
            
            if let subtitle = chapterSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let group = scanlationGroup {
                Text(group)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension View {
    func measureSize(perform action: @escaping (CGSize) -> CGPoint) -> some View {
        self.modifier(MeasureSizeModifier(perform: action))
    }
}

struct MeasureSizeModifier: ViewModifier {
    let perform: (CGSize) -> CGPoint
    
    @State private var size: CGSize = .zero
    @State private var position: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                size = newSize
                position = perform(newSize)
            }
            .offset(x: position.x, y: position.y)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Example usage for tag butto

// Example usage for formatted tags
struct TagsFlowLayout: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8, data: tags.indices.map { TagItem(id: tags[$0], text: tags[$0]) }) { item in
            Text(item.text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

// Helper model for formatted tags
private struct TagItem: Identifiable {
    let id: String
    let text: String
}

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MangaListViewModel
    @State private var yearString: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    ClearableTextField(
                        placeholder: "Manga Title",
                        text: $viewModel.filter.titleSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                    
                    ClearableTextField(
                        placeholder: "Author Name",
                        text: $viewModel.filter.authorSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                    
                    ClearableTextField(
                        placeholder: "Artist Name",
                        text: $viewModel.filter.artistSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                }
                
                // Rest of the existing sections...
                Section(header: Text("Sort By")) {
                    Picker("Sort Option", selection: $viewModel.filter.sortOption) {
                        ForEach(MangaListViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Content Rating")) {
                    Picker("Content Rating", selection: $viewModel.filter.contentRating) {
                        Text("Any").tag(nil as ContentRating?)
                        ForEach(ContentRating.allCases, id: \.self) { rating in
                            Text(rating.displayName).tag(rating as ContentRating?)
                        }
                    }
                }
                
                Section(header: Text("Demographics")) {
                    Picker("Demographics", selection: $viewModel.filter.selectedDemographic) {
                        Text("Any").tag(nil as PublicationDemographic?)
                        ForEach(PublicationDemographic.allCases, id: \.self) { demographic in
                            Text(demographic.displayName).tag(demographic as PublicationDemographic?)
                        }
                    }
                }
                
                Section(header: Text("Publication Year")) {
                    TextField("Year (e.g., 2020)", text: $yearString)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Tags").textCase(.none)) {
                    TagFilterView(viewModel: viewModel)
                        .frame(minHeight: UIScreen.main.bounds.height * 1)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Apply") {
                if let year = Int(yearString) {
                    viewModel.filter.publicationYear = year
                } else {
                    viewModel.filter.publicationYear = nil
                }
                
                presentationMode.wrappedValue.dismiss()
                Task {
                    await viewModel.reloadData()
                }
            })
        }
    }
}

extension MangaDexAPI {
    static func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request: URLRequest
        
        switch endpoint {
        case .manga(let parameters):
            var components = URLComponents(string: "\(baseURL)/manga")!
            
            // Convert dictionary to array of URLQueryItem to handle multiple values for the same key
            var queryItems: [URLQueryItem] = []
            for (key, value) in parameters {
                if key.contains("[]") {
                    // Handle array parameters
                    if value.contains(",") {
                        // Split comma-separated values into multiple query items
                        let values = value.split(separator: ",")
                        for val in values {
                            queryItems.append(URLQueryItem(name: key, value: String(val)))
                        }
                    } else {
                        queryItems.append(URLQueryItem(name: key, value: value))
                    }
                } else {
                    queryItems.append(URLQueryItem(name: key, value: value))
                }
            }
            
            components.queryItems = queryItems
            guard let url = components.url else {
                throw APIError.invalidResponse
            }
            request = URLRequest(url: url)
            
        default:
            request = URLRequest(url: endpoint.url)
        }
        
        // Debug print
        print("Final URL:", request.url?.absoluteString ?? "nil")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

import UIKit

// MARK: - Models
struct ChapterProgress: Codable {
    let chapterId: String
    let currentPage: Int
    let totalPages: Int
    
    var progressPercentage: Double {
        guard totalPages > 1 else { return 0 }
        return Double(currentPage) / Double(totalPages - 1)
    }
}

// MARK: - Progress Storage
final class ReadingProgressStorage: ObservableObject {
    @Published private(set) var progress: [String: ChapterProgress] = [:]
    
    private let defaults = UserDefaults.standard
    private let key = "mangaReadingProgress"
    
    init() {
        loadProgress()
    }
    
    private func loadProgress() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ChapterProgress].self, from: data) else {
            return
        }
        progress = decoded
    }
    
    func updateProgress(for chapterId: String, currentPage: Int, totalPages: Int) {
        let progress = ChapterProgress(
            chapterId: chapterId,
            currentPage: currentPage,
            totalPages: totalPages
        )
        self.progress[chapterId] = progress
        
        if let encoded = try? JSONEncoder().encode(self.progress) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func getProgress(for chapterId: String) -> ChapterProgress? {
        return progress[chapterId]
    }
}

// MARK: - Page Loading Manager
final class PageLoadingManager: ObservableObject {
    @Published private(set) var loadedImages: [Int: UIImage] = [:]
    @Published private(set) var isLoading = false
    private(set) var pageUrls: [URL] = []
    
    private let preloadBuffer = 2
    
    func setPages(_ urls: [URL]) {
        pageUrls = urls
        // Clear existing cache when new pages are set
        loadedImages.removeAll()
    }
    
    func preloadPages(around index: Int) async {
        // Guard against empty page array
        guard !pageUrls.isEmpty else { return }
        
        // Ensure index is within bounds
        let safeIndex = max(0, min(index, pageUrls.count - 1))
        
        // Calculate start and end indices
        let startIndex = max(0, safeIndex - 1)
        let endIndex = min(pageUrls.count - 1, safeIndex + preloadBuffer)
        
        // Only proceed if we have a valid range
        guard startIndex <= endIndex else { return }
        
        // Load pages in the range
        for pageIndex in startIndex...endIndex {
            // Skip if image is already loaded
            guard loadedImages[pageIndex] == nil else { continue }
            
            await loadPage(at: pageIndex)
        }
    }
    
    private func loadPage(at index: Int) async {
        // Additional bounds checking for safety
        guard index >= 0,
              index < pageUrls.count,
              loadedImages[index] == nil else {
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: pageUrls[index])
            
            // Verify we got a successful response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                print("Failed to load valid image for page \(index)")
                return
            }
            
            await MainActor.run {
                loadedImages[index] = image
            }
        } catch {
            print("Failed to load page \(index): \(error)")
        }
    }
    
    func clearCache() {
        loadedImages.removeAll()
    }
    
    // Helper method to check if a specific page is loaded
    func isPageLoaded(_ index: Int) -> Bool {
        loadedImages[index] != nil
    }
    
    // Helper method to get the total number of pages
    var pageCount: Int {
        pageUrls.count
    }
}

// MARK: - Page View Controller
final class MangaPageViewController: UIViewController {
    private var pageViewController: UIPageViewController!
    private(set) var currentPage: Int
    private var totalPages: Int
    var loadedImages: [Int: UIImage]
    private var onPageChanged: (Int) -> Void
    private var onInteraction: () -> Void
    
    init(currentPage: Int,
         totalPages: Int,
         loadedImages: [Int: UIImage],
         onPageChanged: @escaping (Int) -> Void,
         onInteraction: @escaping () -> Void) {
        self.currentPage = min(max(currentPage, 0), totalPages - 1)
        self.totalPages = totalPages
        self.loadedImages = loadedImages
        self.onPageChanged = onPageChanged
        self.onInteraction = onInteraction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupTapGesture()
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let initialVC = createContentViewController(for: currentPage)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        onInteraction()
    }
    
    // Add the missing createContentViewController method
    private func createContentViewController(for page: Int) -> UIViewController {
        let contentVC = UIViewController()
        contentVC.view.backgroundColor = .systemBackground
        contentVC.view.tag = page
        
        if let image = loadedImages[page] {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            contentVC.view.addSubview(imageView)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentVC.view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentVC.view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentVC.view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentVC.view.bottomAnchor)
            ])
        } else {
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            contentVC.view.addSubview(spinner)
            
            spinner.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: contentVC.view.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: contentVC.view.centerYAnchor)
            ])
        }
        
        return contentVC
    }
    
    // Add the missing updateLoadedImages method
    func updateLoadedImages(_ newImages: [Int: UIImage]) {
        loadedImages = newImages
        if let currentVC = pageViewController.viewControllers?.first {
            let currentIndex = currentVC.view.tag
            let newVC = createContentViewController(for: currentIndex)
            pageViewController.setViewControllers([newVC], direction: .forward, animated: false)
        }
    }
}


// MARK: - UIPageViewController DataSource & Delegate
extension MangaPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        let previousIndex = currentIndex + 1 // Right-to-left reading
        guard previousIndex < totalPages else { return nil }
        return createContentViewController(for: previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        let nextIndex = currentIndex - 1 // Right-to-left reading
        guard nextIndex >= 0 else { return nil }
        return createContentViewController(for: nextIndex)
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard finished && completed,
              let visibleViewController = pageViewController.viewControllers?.first else { return }
        
        let newPage = visibleViewController.view.tag
        if currentPage != newPage {
            currentPage = newPage
            onPageChanged(newPage)
        }
    }
}

extension MangaPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

// MARK: - SwiftUI View
struct PagedChapterReaderView: View {
    let chapter: Chapter
    
    @StateObject private var pageLoadingManager = PageLoadingManager()
    @StateObject private var progressStorage = ReadingProgressStorage()
    @State private var currentPageIndex = 0
    @State private var showControls = true
    @State private var error: Error?
    @State private var isLoading = true
    @State private var hideControlsWorkItem: DispatchWorkItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Group {
                if isLoading && pageLoadingManager.loadedImages.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if let error = error {
                    ErrorView(error: error) {
                        dismiss()
                    }
                } else {
                    pageViewController
                    
                    if showControls {
                        ControlsOverlay(
                            chapter: chapter,
                            currentPage: currentPageIndex,
                            totalPages: max(pageLoadingManager.pageUrls.count, 1),
                            progress: progressStorage.getProgress(for: chapter.id)?.progressPercentage ?? 0,
                            onDismiss: {
                                saveProgress()
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadChapter()
        }
    }
    
    private var pageViewController: some View {
        PageViewControllerRepresentable(
            currentPage: currentPageIndex,
            totalPages: pageLoadingManager.pageUrls.count,
            loadedImages: pageLoadingManager.loadedImages,
            onPageChanged: { newPage in
                currentPageIndex = newPage
                saveProgress()
                Task {
                    await pageLoadingManager.preloadPages(around: newPage)
                }
            },
            onInteraction: handleTap
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private func handleTap() {
        hideControlsWorkItem?.cancel()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        
        if showControls {
            let workItem = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }
    
    private func loadChapter() async {
        isLoading = true
        
        do {
            let serverURL = URL(string: "https://api.mangadex.org/at-home/server/\(chapter.id)")!
            let (serverData, _) = try await URLSession.shared.data(from: serverURL)
            let serverResponse = try JSONDecoder().decode(ChapterServerResponse.self, from: serverData)
            
            let urls = serverResponse.chapter.dataSaver.map { fileName in
                URL(string: "\(serverResponse.baseUrl)/data-saver/\(serverResponse.chapter.hash)/\(fileName)")!
            }
            
            await MainActor.run {
                pageLoadingManager.setPages(urls)
                
                if let savedProgress = progressStorage.getProgress(for: chapter.id) {
                    currentPageIndex = savedProgress.currentPage
                }
                
                isLoading = false
            }
            
            await pageLoadingManager.preloadPages(around: currentPageIndex)
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
    
    private func saveProgress() {
        progressStorage.updateProgress(
            for: chapter.id,
            currentPage: currentPageIndex,
            totalPages: pageLoadingManager.pageUrls.count
        )
    }
}

// MARK: - Supporting Views
struct ErrorView: View {
    let error: Error
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error loading chapter")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Go Back") {
                onDismiss()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct ControlsOverlay: View {
    let chapter: Chapter
    let currentPage: Int
    let totalPages: Int
    let progress: Double
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
                Text("Chapter \(chapter.attributes.chapter ?? "N/A")")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.7))
            
            Spacer()
            
            HStack {
                Text("\(currentPage + 1) / \(totalPages)")
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - SwiftUI Representative
struct PageViewControllerRepresentable: UIViewControllerRepresentable {
    let currentPage: Int
    let totalPages: Int
    let loadedImages: [Int: UIImage]
    let onPageChanged: (Int) -> Void
    let onInteraction: () -> Void
    
    func makeUIViewController(context: Context) -> MangaPageViewController {
        return MangaPageViewController(
            currentPage: currentPage,
            totalPages: totalPages,
            loadedImages: loadedImages,
            onPageChanged: onPageChanged,
            onInteraction: onInteraction
        )
    }
    
    func updateUIViewController(_ pageViewController: MangaPageViewController, context: Context) {
        if pageViewController.loadedImages != loadedImages {
            pageViewController.updateLoadedImages(loadedImages)
        }
    }
}

// MARK: - Authentication Models
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

// MARK: - Authentication Manager
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

// MARK: - Keychain Helper
class KeychainHelper {
    private let accessTokenKey = "mangadex.accessToken"
    private let refreshTokenKey = "mangadex.refreshToken"
    
    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }
    
    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }
    
    func deleteTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }
    
    private func save(_ string: String, forKey key: String) {
        let data = string.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Login View
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

// MARK: - User Profile View
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

// MARK: - Models
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
    
    struct ChapterFeed: Identifiable {
        let id: String
        let mangaTitle: String
        let chapterNumber: String?
        let chapterTitle: String?
        let scanlationGroup: String?
        let publishedAt: Date
        let manga: Manga
        let coverUrl: URL?
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

// MARK: - Follows View
//struct FollowsView: View {
//    @ObservedObject var followsManager: FollowsManager
//    
//    // Create a sorted array of manga from the dictionary
//    private var sortedManga: [Manga] {
//        Array(followsManager.followedManga.values)
//            .sorted { manga1, manga2 in
//                manga1.lastUpdateDate > manga2.lastUpdateDate
//            }
//    }
//    
//    var body: some View {
//        Group {
//            if followsManager.isSyncing {
//                VStack {
//                    ProgressView()
//                    Text("Syncing follows...")
//                        .foregroundColor(.secondary)
//                }
//            } else if followsManager.followedManga.isEmpty {
//                VStack(spacing: 16) {
//                    Image(systemName: "heart.slash")
//                        .font(.system(size: 48))
//                        .foregroundColor(.gray)
//                    Text("No followed manga")
//                        .font(.headline)
//                    Text("Manga you follow will appear here")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//            } else {
//                List {
//                    ForEach(sortedManga) { manga in
//                        NavigationLink(destination: MangaDetailView(manga: manga, followsManager: followsManager)) {
//                            VStack(alignment: .leading, spacing: 4) {
//                                MangaRowView(manga: manga)
//                                
//                                // Add a relative date display
//                                Text("Updated \(manga.lastUpdateDate.relativeFormatted)")
//                                    .font(.caption2)
//                                    .foregroundColor(.secondary)
//                                    .padding(.leading, 98) // Align with title (considering cover width)
//                            }
//                        }
//                    }
//                }
//                .listStyle(PlainListStyle())
//            }
//        }
//        .navigationTitle("Following")
//        .refreshable {
//            await followsManager.syncWithServer()
//        }
//        .task {
//            await followsManager.syncWithServer()
//        }
//    }
//}


// MARK: - Follow Button
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

// MARK: - Authentication Errors
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

extension DateFormatter {
    static let mangaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+00:00"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// Add a computed property to Manga for easier date comparison
extension Manga {
    var lastUpdateDate: Date {
        DateFormatter.mangaDateFormatter.date(from: attributes.updatedAt) ?? .distantPast
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// First, let's create a model for the feed response
struct ChapterFeed: Identifiable {
    let id: String
    let mangaTitle: String
    let chapterNumber: String?
    let chapterTitle: String?
    let scanlationGroup: String?
    let publishedAt: Date
    let manga: Manga
}

//class FollowsManager: ObservableObject {
//    @Published private(set) var followedManga: [String: Manga] = [:]
//    @Published private(set) var latestChapters: [ChapterFeed] = []
//    private let authManager: AuthenticationManager
//    
//    func loadFollowedMangaFeed() async throws {
//        guard authManager.isAuthenticated,
//              let token = authManager.keychainHelper.getAccessToken() else {
//            throw AuthError.tokenExpired
//        }
//        
//        var components = URLComponents(string: "https://api.mangadex.org/user/follows/manga/feed")!
//        components.queryItems = [
//            URLQueryItem(name: "limit", value: "100"),
//            URLQueryItem(name: "translatedLanguage[]", value: "en"),
//            URLQueryItem(name: "order[publishAt]", value: "desc"),
//            URLQueryItem(name: "includes[]", value: "manga"),
//            URLQueryItem(name: "includes[]", value: "scanlation_group"),
//            // Include all content ratings
//            URLQueryItem(name: "contentRating[]", value: "safe"),
//            URLQueryItem(name: "contentRating[]", value: "suggestive"),
//            URLQueryItem(name: "contentRating[]", value: "erotica"),
//            URLQueryItem(name: "contentRating[]", value: "pornographic")
//        ]
//        
//        var request = URLRequest(url: components.url!)
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw AuthError.serverError("Failed to fetch manga feed")
//        }
//        
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        let feedResponse = try decoder.decode(ChapterListResponse.self, from: data)
//        
//        // Process chapters into ChapterFeed objects
//        let feeds = feedResponse.data.compactMap { chapter -> ChapterFeed? in
//            guard let manga = chapter.relationships.first(where: { $0.type == "manga" }) else {
//                return nil
//            }
//            
//            let scanlationGroup = chapter.relationships
//                .first(where: { $0.type == "scanlation_group" })?
//                .attributes?.name
//            
//            return ChapterFeed(
//                id: chapter.id,
//                mangaTitle: manga.attributes?.title["en"] ?? "Unknown",
//                chapterNumber: chapter.attributes.chapter,
//                chapterTitle: chapter.attributes.title,
//                scanlationGroup: scanlationGroup,
//                publishedAt: DateFormatter.mangaDateFormatter.date(from: chapter.attributes.publishAt) ?? Date(),
//                manga: manga
//            )
//        }
//        
//        await MainActor.run {
//            self.latestChapters = feeds
//        }
//    }
//    
//    func checkIfFollowing(mangaId: String) async throws -> Bool {
//        guard authManager.isAuthenticated,
//              let token = authManager.keychainHelper.getAccessToken() else {
//            throw AuthError.tokenExpired
//        }
//        
//        let url = URL(string: "https://api.mangadex.org/user/follows/manga/\(mangaId)")!
//        var request = URLRequest(url: url)
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        
//        let (_, response) = try await URLSession.shared.data(for: request)
//        return (response as? HTTPURLResponse)?.statusCode == 200
//    }
//    
//    func toggleFollow(manga: Manga) async throws {
//        guard authManager.isAuthenticated,
//              let token = authManager.keychainHelper.getAccessToken() else {
//            throw AuthError.tokenExpired
//        }
//        
//        let isCurrentlyFollowing = try await checkIfFollowing(mangaId: manga.id)
//        let url = URL(string: "https://api.mangadex.org/manga/\(manga.id)/follow")!
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = isCurrentlyFollowing ? "DELETE" : "POST"
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        
//        let (_, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw AuthError.serverError("Failed to update follow status")
//        }
//        
//        // Update local state after successful API call
//        await MainActor.run {
//            if isCurrentlyFollowing {
//                followedManga.removeValue(forKey: manga.id)
//            } else {
//                followedManga[manga.id] = manga
//            }
//        }
//        
//        // Refresh the feed after updating follows
//        try await loadFollowedMangaFeed()
//    }
//}

//struct FollowsView: View {
//    @ObservedObject var followsManager: FollowsManager
//    @State private var isLoading = false
//    @State private var error: Error?
//    
//    var body: some View {
//        Group {
//            if followsManager.latestChapters.isEmpty {
//                VStack(spacing: 16) {
//                    if isLoading {
//                        ProgressView()
//                    } else {
//                        Image(systemName: "heart.slash")
//                            .font(.system(size: 48))
//                            .foregroundColor(.gray)
//                        Text("No followed manga")
//                            .font(.headline)
//                        Text("Manga you follow will appear here")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//            } else {
//                List {
//                    ForEach(followsManager.latestChapters) { chapter in
//                        NavigationLink(destination: PagedChapterReaderView(chapter: chapter)) {
//                            ChapterFeedRow(chapter: chapter)
//                        }
//                    }
//                }
//                .listStyle(PlainListStyle())
//            }
//        }
//        .navigationTitle("Following")
//        .task {
//            await loadFeed()
//        }
//        .refreshable {
//            await loadFeed()
//        }
//        .alert("Error", isPresented: .constant(error != nil)) {
//            Button("OK") { error = nil }
//        } message: {
//            Text(error?.localizedDescription ?? "Unknown error")
//        }
//    }
//    
//    private func loadFeed() async {
//        isLoading = true
//        do {
//            try await followsManager.loadFollowedMangaFeed()
//        } catch {
//            self.error = error
//        }
//        isLoading = false
//    }
//}

struct ChapterFeedRow: View {
    let chapter: ChapterFeed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapter.mangaTitle)
                .font(.headline)
            
            HStack {
                if let number = chapter.chapterNumber {
                    Text("Chapter \(number)")
                        .font(.subheadline)
                }
                if let title = chapter.chapterTitle {
                    Text("- \(title)")
                        .font(.subheadline)
                }
            }
            
            if let group = chapter.scanlationGroup {
                Text(group)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(chapter.publishedAt.relativeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

// MARK: - Library Manager
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

// First, the FollowButton needs to become a LibraryButton that handles reading status
struct LibraryButton: View {
    @ObservedObject var libraryManager: LibraryManager
    let manga: Manga
    @State private var isLoading = false
    @State private var showStatusPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var currentStatus: MangaReadingStatus? {
        libraryManager.libraryManga[manga.id]?.1
    }
    
    var body: some View {
        Button(action: { showStatusPicker = true }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: currentStatus == nil ? "book" : "book.fill")
                }
                Text(currentStatus?.displayTitle ?? "Add to Library")
            }
            .foregroundColor(currentStatus == nil ? .blue : .green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 2)
        }
        .disabled(isLoading)
        .actionSheet(isPresented: $showStatusPicker) {
            ActionSheet(
                title: Text("Update Reading Status"),
                buttons: statusButtons
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusButtons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = [
            .default(Text("Reading")) { updateStatus(.reading) },
            .default(Text("Plan to Read")) { updateStatus(.planToRead) },
            .default(Text("Completed")) { updateStatus(.completed) },
            .default(Text("On Hold")) { updateStatus(.onHold) },
            .default(Text("Dropped")) { updateStatus(.dropped) },
            .default(Text("Re-reading")) { updateStatus(.reReading) }
        ]
        
        // Add remove option if manga is in library
        if currentStatus != nil {
            buttons.append(.destructive(Text("Remove from Library")) {
                removeMangaFromLibrary()
            })
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func updateStatus(_ status: MangaReadingStatus) {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await libraryManager.updateMangaStatus(manga, status: status)
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
    
    private func removeMangaFromLibrary() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await libraryManager.removeMangaFromLibrary(manga)
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

// Update the FollowsView to become LibraryView
struct LibraryView: View {
    @ObservedObject var libraryManager: LibraryManager
    @ObservedObject var authManager: AuthenticationManager  // Add authManager
    @State private var selectedStatus: MangaReadingStatus?
    
    private var displayedManga: [Manga] {
        Array(libraryManager.libraryManga.values)
            .filter { selectedStatus == nil || $0.1 == selectedStatus }
            .sorted { $0.0.lastUpdateDate > $1.0.lastUpdateDate }
            .map { $0.0 }
    }
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                VStack(spacing: 16) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Please log in to view your library")
                        .font(.headline)
                    NavigationLink("Go to Login", destination: LoginView())
                        .buttonStyle(.bordered)
                }
            } else if libraryManager.isSyncing && libraryManager.libraryManga.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading library...")
                        .foregroundColor(.secondary)
                }
            } else if libraryManager.libraryManga.isEmpty {
                EmptyLibraryView()
            } else {
                LibraryContentView(
                    displayedManga: displayedManga,
                    selectedStatus: $selectedStatus,
                    hasPlaceholders: displayedManga.contains { $0.isPlaceholder },
                    libraryManager: libraryManager
                )
            }
        }
        .navigationTitle("Library")
        .task {
            // Only sync if authenticated
            if authManager.isAuthenticated {
                await libraryManager.syncLibrary()
            }
        }
        .refreshable {
            if authManager.isAuthenticated {
                await libraryManager.syncLibrary()
            }
        }
        .alert("Error", isPresented: .constant(libraryManager.error != nil)) {
            Button("OK") {
                libraryManager.error = nil
            }
        } message: {
            if let error = libraryManager.error {
                Text(error.localizedDescription)
            }
        }
    }
}
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No manga in library")
                .font(.headline)
            Text("Manga you add to your library will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct LibraryContentView: View {
    let displayedManga: [Manga]
    @Binding var selectedStatus: MangaReadingStatus?
    let hasPlaceholders: Bool
    let libraryManager: LibraryManager
    
    var body: some View {
        VStack {
            // Status picker remains the same
            Picker("Status", selection: $selectedStatus) {
                Text("All").tag(nil as MangaReadingStatus?)
                ForEach(MangaReadingStatus.allCases, id: \.self) { status in
                    Text(status.displayTitle).tag(status as MangaReadingStatus?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            List {
                ForEach(displayedManga) { manga in
                    NavigationLink(
                        destination: MangaDetailView(
                            manga: manga,
                            libraryManager: libraryManager
                        )
                    ) {
                        MangaRowView(manga: manga)
                            .redacted(reason: manga.isPlaceholder ? .placeholder : [])
                    }
                    .disabled(manga.isPlaceholder)
                }
            }
            .listStyle(PlainListStyle())
            
            if hasPlaceholders {
                ProgressView()
                    .padding()
            }
        }
    }
}


enum MangaReadingStatus: String, Codable, CaseIterable {
    case reading = "reading"
    case onHold = "on_hold"
    case planToRead = "plan_to_read"
    case dropped = "dropped"
    case reReading = "re_reading"
    case completed = "completed"
    
    var displayTitle: String {
        switch self {
        case .reading: return "Reading"
        case .planToRead: return "Plan to Read"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .dropped: return "Dropped"
        case .reReading: return "Re-reading"
        }
    }
}

extension Manga {
    var isPlaceholder: Bool {
        // Add additional checks to ensure we identify placeholders correctly
        return attributes.title["en"] == "Loading..." ||
               attributes.updatedAt.isEmpty ||
               relationships.isEmpty
    }
    
    static func placeholder(id: String) -> Manga {
        return Manga(
            id: id,
            attributes: MangaAttributes(
                title: ["en": "Loading..."],
                description: [:],
                year: nil,
                status: "unknown",
                tags: [],
                updatedAt: "",
                rating: nil
            ),
            relationships: []
        )
    }
}

struct CoverImageView: View {
    let manga: Manga
    let width: CGFloat
    let height: CGFloat
    @State private var coverImage: UIImage?
    @State private var isLoading = true
    @Environment(\.redactionReasons) private var redactionReasons
    
    var body: some View {
        Group {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if isLoading && redactionReasons.isEmpty {
                            ProgressView()
                        }
                    }
            }
        }
        .task {
            // Only load if not redacted and not a placeholder
            if redactionReasons.isEmpty && !manga.isPlaceholder {
                await loadCover()
            }
        }
    }
    
    private func loadCover() async {
        guard coverImage == nil else { return }
        isLoading = true
        
        if let coverRel = manga.relationships.first(where: { $0.type == "cover_art" }),
           let filename = coverRel.attributes?.fileName {
            do {
                let imageUrl = URL(string: "https://uploads.mangadex.org/covers/\(manga.id)/\(filename)")!
                let (data, response) = try await URLSession.shared.data(from: imageUrl)
                
                // Verify response and create image
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.coverImage = image
                    self.isLoading = false
                }
            } catch {
                print("Error loading cover for manga \(manga.id): \(error)")
                await MainActor.run { self.isLoading = false }
            }
        } else {
            isLoading = false
        }
    }
}

extension LibraryManager {
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
        let mangaResponse = try decoder.decode(SingleMangaResponse.self, from: data)
        return mangaResponse.data
    }
}
