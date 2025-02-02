import Foundation
import UIKit
import SwiftUI

struct CoverImageView: View {
    let manga: Manga
    let width: CGFloat
    let height: CGFloat
    @State private var coverImage: UIImage?
    @State private var isLoading = true
    @Environment(\.redactionReasons) private var redactionReasons
    
    var body: some View {
        Group {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if isLoading && redactionReasons.isEmpty {
                            ProgressView()
                        }
                    }
            }
        }
        .task {
            // Only load if not redacted and not a placeholder
            if redactionReasons.isEmpty && !manga.isPlaceholder {
                await loadCover()
            }
        }
    }
    
    private func loadCover() async {
        guard coverImage == nil else { return }
        isLoading = true
        
        if let coverRel = manga.relationships.first(where: { $0.type == "cover_art" }),
           let filename = coverRel.attributes?.fileName {
            do {
                let imageUrl = URL(string: "https://uploads.mangadex.org/covers/\(manga.id)/\(filename)")!
                let (data, response) = try await URLSession.shared.data(from: imageUrl)
                
                // Verify response and create image
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.coverImage = image
                    self.isLoading = false
                }
            } catch {
                print("Error loading cover for manga \(manga.id): \(error)")
                await MainActor.run { self.isLoading = false }
            }
        } else {
            isLoading = false
        }
    }
}
