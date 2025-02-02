
import Foundation

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
