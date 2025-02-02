import Foundation
import UIKit
import SwiftUI

struct LibraryButton: View {
    @ObservedObject var libraryManager: LibraryManager
    let manga: Manga
    @State private var isLoading = false
    @State private var showStatusPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var currentStatus: MangaReadingStatus? {
        libraryManager.libraryManga[manga.id]?.1
    }
    
    var body: some View {
        Button(action: { showStatusPicker = true }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: currentStatus == nil ? "book" : "book.fill")
                }
                Text(currentStatus?.displayTitle ?? "Add to Library")
            }
            .foregroundColor(currentStatus == nil ? .blue : .green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 2)
        }
        .disabled(isLoading)
        .actionSheet(isPresented: $showStatusPicker) {
            ActionSheet(
                title: Text("Update Reading Status"),
                buttons: statusButtons
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusButtons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = [
            .default(Text("Reading")) { updateStatus(.reading) },
            .default(Text("Plan to Read")) { updateStatus(.planToRead) },
            .default(Text("Completed")) { updateStatus(.completed) },
            .default(Text("On Hold")) { updateStatus(.onHold) },
            .default(Text("Dropped")) { updateStatus(.dropped) },
            .default(Text("Re-reading")) { updateStatus(.reReading) }
        ]
        
        // Add remove option if manga is in library
        if currentStatus != nil {
            buttons.append(.destructive(Text("Remove from Library")) {
                removeMangaFromLibrary()
            })
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func updateStatus(_ status: MangaReadingStatus) {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await libraryManager.updateMangaStatus(manga, status: status)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func removeMangaFromLibrary() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                try await libraryManager.removeMangaFromLibrary(manga)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
