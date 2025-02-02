
import Foundation

struct MangaResponse: Decodable {
    let data: [Manga]
    let total: Int
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

struct TagResponse: Decodable {
    let data: [Tag]
    let total: Int
}

struct ChapterListResponse: Codable {
    let data: [Chapter]
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case data
        case total
    }
}
