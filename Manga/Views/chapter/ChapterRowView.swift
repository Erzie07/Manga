import Foundation
import UIKit
import SwiftUI

struct ChapterRowView: View {
    let chapter: Chapter
    
    private var chapterTitle: String {
        if let title = chapter.attributes.title, !title.isEmpty {
            return title
        }
        return "Chapter \(chapter.attributes.chapter ?? "N/A")"
    }
    
    private var chapterSubtitle: String? {
        let components = [
            chapter.attributes.volume.map { "Vol. \($0)" },
            chapter.attributes.chapter.map { "Ch. \($0)" }
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
    
    private var scanlationGroup: String? {
        chapter.relationships
            .first(where: { $0.type == "scanlation_group" })?
            .attributes?.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapterTitle)
                .font(.body)
                .foregroundColor(.primary)
            
            if let subtitle = chapterSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let group = scanlationGroup {
                Text(group)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
