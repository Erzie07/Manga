import Foundation
import SwiftUI
import UIKit

struct FlowLayout: View {
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let content: [AnyView]
    
    @State private var totalHeight: CGFloat = 0
    
    init<Data: RandomAccessCollection, Content: View>(
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 16,
        data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Data.Element: Identifiable {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.content = data.map { AnyView(content($0)) }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var x: CGFloat = horizontalPadding
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(content.enumerated()), id: \.offset) { index, view in
                view
                    .alignmentGuide(.leading) { dimensions in
                        let width = dimensions.width
                        let result: CGFloat
                        
                        if (x + width + horizontalPadding > geometry.size.width) {
                            x = horizontalPadding
                            y += maxHeight + spacing
                            maxHeight = 0
                        }
                        
                        result = x
                        x += width + spacing
                        maxHeight = max(maxHeight, dimensions.height)
                        
                        if index == content.count - 1 {
                            DispatchQueue.main.async {
                                self.totalHeight = y + maxHeight
                            }
                        }
                        
                        return -result
                    }
                    .alignmentGuide(.top) { _ in
                        -y
                    }
            }
        }
    }
}

struct TagsFlowLayout: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8, data: tags.indices.map { TagItem(id: tags[$0], text: tags[$0]) }) { item in
            Text(item.text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

