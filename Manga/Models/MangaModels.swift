
import Foundation

struct Manga: Identifiable, Decodable {
    let id: String
    let attributes: MangaAttributes
    let relationships: [Relationship]
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

extension Manga {
    var lastUpdateDate: Date {
        DateFormatter.mangaDateFormatter.date(from: attributes.updatedAt) ?? .distantPast
    }
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
