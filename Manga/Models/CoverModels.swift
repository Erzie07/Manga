import Foundation

struct CoverAttributes: Decodable {
    let fileName: String
}

struct CoverArt: Decodable {
    let id: String
    let type: String
    let attributes: CoverAttributes
}
