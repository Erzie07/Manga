import Foundation
import UIKit
import SwiftUI

struct ChapterFeedRow: View {
    let chapter: ChapterFeed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapter.mangaTitle)
                .font(.headline)
            
            HStack {
                if let number = chapter.chapterNumber {
                    Text("Chapter \(number)")
                        .font(.subheadline)
                }
                if let title = chapter.chapterTitle {
                    Text("- \(title)")
                        .font(.subheadline)
                }
            }
            
            if let group = chapter.scanlationGroup {
                Text(group)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(chapter.publishedAt.relativeFormatted)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
