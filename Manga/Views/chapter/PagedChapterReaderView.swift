import Foundation
import UIKit
import SwiftUI

struct PagedChapterReaderView: View {
    let chapter: Chapter
    
    @StateObject private var pageLoadingManager = PageLoadingManager()
    @StateObject private var progressStorage = ReadingProgressStorage()
    @State private var currentPageIndex = 0
    @State private var showControls = true
    @State private var error: Error?
    @State private var isLoading = true
    @State private var hideControlsWorkItem: DispatchWorkItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Group {
                if isLoading && pageLoadingManager.loadedImages.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if let error = error {
                    ErrorView(error: error) {
                        dismiss()
                    }
                } else {
                    pageViewController
                    
                    if showControls {
                        ControlsOverlay(
                            chapter: chapter,
                            currentPage: currentPageIndex,
                            totalPages: max(pageLoadingManager.pageUrls.count, 1),
                            progress: progressStorage.getProgress(for: chapter.id)?.progressPercentage ?? 0,
                            onDismiss: {
                                saveProgress()
                                dismiss()
                            }
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true) // Add this modifier
                .navigationBarBackButtonHidden(true) // Optional: Hide back button
                .statusBar(hidden: true) // Optional: Hide status bar
                .edgesIgnoringSafeArea(.all)
        .task {
            await loadChapter()
        }
    }
    
    private var pageViewController: some View {
        PageViewControllerRepresentable(
            currentPage: currentPageIndex,
            totalPages: pageLoadingManager.pageUrls.count,
            loadedImages: pageLoadingManager.loadedImages,
            onPageChanged: { newPage in
                currentPageIndex = newPage
                saveProgress()
                Task {
                    await pageLoadingManager.preloadPages(around: newPage)
                }
            },
            onInteraction: handleTap
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private func handleTap() {
        hideControlsWorkItem?.cancel()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        
        // Auto-hide controls after 3 seconds if shown
        if showControls {
            let workItem = DispatchWorkItem {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }
    
    private func loadChapter() async {
        
        if let savedProgress = progressStorage.getProgress(for: chapter.id) {
            currentPageIndex = min(savedProgress.currentPage, max(pageLoadingManager.pageUrls.count - 1, 0))
        }
        
        isLoading = true
        
        do {
            let serverURL = URL(string: "https://api.mangadex.org/at-home/server/\(chapter.id)")!
            let (serverData, _) = try await URLSession.shared.data(from: serverURL)
            let serverResponse = try JSONDecoder().decode(ChapterServerResponse.self, from: serverData)
            
            let urls = serverResponse.chapter.dataSaver.map { fileName in
                URL(string: "\(serverResponse.baseUrl)/data-saver/\(serverResponse.chapter.hash)/\(fileName)")!
            }
            
            await MainActor.run {
                pageLoadingManager.setPages(urls)
                
                if let savedProgress = progressStorage.getProgress(for: chapter.id) {
                    currentPageIndex = savedProgress.currentPage
                }
                
                isLoading = false
            }
            
            await pageLoadingManager.preloadPages(around: currentPageIndex)
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
    
    // When saving progress
    private func saveProgress() {
        let clampedPage = min(currentPageIndex, max(pageLoadingManager.pageUrls.count - 1, 0))
        progressStorage.updateProgress(
            for: chapter.id,
            currentPage: clampedPage,
            totalPages: pageLoadingManager.pageUrls.count
        )
    }
}

struct ControlsOverlay: View {
    let chapter: Chapter
    let currentPage: Int
    let totalPages: Int
    let progress: Double
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
                Text("Chapter \(chapter.attributes.chapter ?? "N/A")")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.7))
            
            Spacer()
            
            HStack {
                Text("\(currentPage + 1) / \(totalPages)")
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}


