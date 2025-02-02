
import Foundation

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

enum TagInclusionMode: String, CaseIterable {
    case and = "And"
    case or = "Or"
}

struct TagItem: Identifiable {
    let id: String
    let text: String
}

extension Tag: CustomStringConvertible {
    var description: String {
        return "Tag(id: \(id), name: \(attributes.name["en"] ?? "unknown"))"
    }
}


extension TagCategory: Comparable {
    static func < (lhs: TagCategory, rhs: TagCategory) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}
