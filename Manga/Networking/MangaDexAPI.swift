import Foundation

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
