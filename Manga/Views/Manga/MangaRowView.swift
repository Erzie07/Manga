import Foundation
import UIKit
import SwiftUI

struct MangaRowView: View {
    let manga: Manga
    
    var body: some View {
        HStack {
            CoverImageView(manga: manga, width: 90, height: 120)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.attributes.title["en"] ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                Text(manga.attributes.updatedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let year = manga.attributes.year {
                    Text("Year: \(year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
        }
    }
}
