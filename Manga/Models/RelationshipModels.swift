
import Foundation

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
