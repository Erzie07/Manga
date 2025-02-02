
import Foundation

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
