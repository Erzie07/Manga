import Foundation
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
