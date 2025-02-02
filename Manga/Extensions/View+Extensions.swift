import Foundation
import SwiftUI

extension View {
    func browseToolbar(showingFilters: Binding<Bool>) -> some View {
        self.modifier(BrowseToolbarModifier(showingFilters: showingFilters))
    }
}

extension View {
    func measureSize(perform action: @escaping (CGSize) -> CGPoint) -> some View {
        self.modifier(MeasureSizeModifier(perform: action))
    }
}

struct BrowseToolbarModifier: ViewModifier {
    @Binding var showingFilters: Bool
    
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                        .accessibilityLabel("Filter")
                }
            }
        }
    }
}

struct MeasureSizeModifier: ViewModifier {
    let perform: (CGSize) -> CGPoint
    
    @State private var size: CGSize = .zero
    @State private var position: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                size = newSize
                position = perform(newSize)
            }
            .offset(x: position.x, y: position.y)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
