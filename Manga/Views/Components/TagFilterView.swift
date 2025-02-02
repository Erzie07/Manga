import Foundation
import SwiftUI
import UIKit

struct TagFilterView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MangaListViewModel
    
    func makeUIViewController(context: Context) -> TagFilterViewController {
        return TagFilterViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: TagFilterViewController, context: Context) {
        // Update if needed
    }
}
