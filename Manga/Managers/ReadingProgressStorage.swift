import Foundation

final class ReadingProgressStorage: ObservableObject {
    @Published private(set) var progress: [String: ChapterProgress] = [:]
    
    private let defaults = UserDefaults.standard
    private let key = "mangaReadingProgress"
    
    init() {
        loadProgress()
    }
    
    private func loadProgress() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ChapterProgress].self, from: data) else {
            return
        }
        progress = decoded
    }
    
    func updateProgress(for chapterId: String, currentPage: Int, totalPages: Int) {
        let progress = ChapterProgress(
            chapterId: chapterId,
            currentPage: currentPage,
            totalPages: totalPages
        )
        self.progress[chapterId] = progress
        
        if let encoded = try? JSONEncoder().encode(self.progress) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func getProgress(for chapterId: String) -> ChapterProgress? {
        return progress[chapterId]
    }
}
