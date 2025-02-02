import Foundation
import UIKit
import SwiftUI

struct LibraryView: View {
    @ObservedObject var libraryManager: LibraryManager
    @ObservedObject var authManager: AuthenticationManager  // Add authManager
    @State private var selectedStatus: MangaReadingStatus?
    
    private var displayedManga: [Manga] {
        Array(libraryManager.libraryManga.values)
            .filter { selectedStatus == nil || $0.1 == selectedStatus }
            .sorted { $0.0.lastUpdateDate > $1.0.lastUpdateDate }
            .map { $0.0 }
    }
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                VStack(spacing: 16) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Please log in to view your library")
                        .font(.headline)
                    NavigationLink("Go to Login", destination: LoginView())
                        .buttonStyle(.bordered)
                }
            } else if libraryManager.isSyncing && libraryManager.libraryManga.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading library...")
                        .foregroundColor(.secondary)
                }
            } else if libraryManager.libraryManga.isEmpty {
                EmptyLibraryView()
            } else {
                LibraryContentView(
                    displayedManga: displayedManga,
                    selectedStatus: $selectedStatus,
                    hasPlaceholders: displayedManga.contains { $0.isPlaceholder },
                    libraryManager: libraryManager
                )
            }
        }
        .navigationTitle("Library")
        .task {
            // Only sync if authenticated
            if authManager.isAuthenticated {
                await libraryManager.syncLibrary()
            }
        }
        .refreshable {
            if authManager.isAuthenticated {
                await libraryManager.syncLibrary()
            }
        }
        .alert("Error", isPresented: .constant(libraryManager.error != nil)) {
            Button("OK") {
                libraryManager.error = nil
            }
        } message: {
            if let error = libraryManager.error {
                Text(error.localizedDescription)
            }
        }
    }
}
struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No manga in library")
                .font(.headline)
            Text("Manga you add to your library will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct LibraryContentView: View {
    let displayedManga: [Manga]
    @Binding var selectedStatus: MangaReadingStatus?
    let hasPlaceholders: Bool
    let libraryManager: LibraryManager
    
    var body: some View {
        VStack {
            // Status picker remains the same
            Picker("Status", selection: $selectedStatus) {
                Text("All").tag(nil as MangaReadingStatus?)
                ForEach(MangaReadingStatus.allCases, id: \.self) { status in
                    Text(status.displayTitle).tag(status as MangaReadingStatus?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            List {
                ForEach(displayedManga) { manga in
                    NavigationLink(
                        destination: MangaDetailView(
                            manga: manga,
                            libraryManager: libraryManager
                        )
                    ) {
                        MangaRowView(manga: manga)
                            .redacted(reason: manga.isPlaceholder ? .placeholder : [])
                    }
                    .disabled(manga.isPlaceholder)
                }
            }
            .listStyle(PlainListStyle())
            
            if hasPlaceholders {
                ProgressView()
                    .padding()
            }
        }
    }
}
