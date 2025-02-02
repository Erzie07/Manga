import Foundation
import UIKit

final class PageLoadingManager: ObservableObject {
    @Published private(set) var loadedImages: [Int: UIImage] = [:]
    @Published private(set) var isLoading = false
    private(set) var pageUrls: [URL] = []
    
    private let preloadBuffer = 2
    
    func setPages(_ urls: [URL]) {
        pageUrls = urls
        // Clear existing cache when new pages are set
        loadedImages.removeAll()
    }
    
    func preloadPages(around index: Int) async {
        // Guard against empty page array
        guard !pageUrls.isEmpty else { return }
        
        // Ensure index is within bounds
        let safeIndex = max(0, min(index, pageUrls.count - 1))
        
        // Calculate start and end indices
        let startIndex = max(0, safeIndex - 1)
        let endIndex = min(pageUrls.count - 1, safeIndex + preloadBuffer)
        
        // Only proceed if we have a valid range
        guard startIndex <= endIndex else { return }
        
        // Load pages in the range
        for pageIndex in startIndex...endIndex {
            // Skip if image is already loaded
            guard loadedImages[pageIndex] == nil else { continue }
            
            await loadPage(at: pageIndex)
        }
    }
    
    private func loadPage(at index: Int) async {
        // Additional bounds checking for safety
        guard index >= 0,
              index < pageUrls.count,
              loadedImages[index] == nil else {
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: pageUrls[index])
            
            // Verify we got a successful response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                print("Failed to load valid image for page \(index)")
                return
            }
            
            await MainActor.run {
                loadedImages[index] = image
            }
        } catch {
            print("Failed to load page \(index): \(error)")
        }
    }
    
    func clearCache() {
        loadedImages.removeAll()
    }
    
    // Helper method to check if a specific page is loaded
    func isPageLoaded(_ index: Int) -> Bool {
        loadedImages[index] != nil
    }
    
    // Helper method to get the total number of pages
    var pageCount: Int {
        pageUrls.count
    }
}
