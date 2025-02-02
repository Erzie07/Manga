
import Foundation

struct ChapterProgress: Codable {
    let chapterId: String
    let currentPage: Int
    let totalPages: Int
    
    var progressPercentage: Double {
        guard totalPages > 1 else { return 0 }
        return Double(currentPage) / Double(totalPages - 1)
    }
}
