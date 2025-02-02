import Foundation
import UIKit
import SwiftUI

struct MangaDetailView: View {
    let manga: Manga
    @ObservedObject var libraryManager: LibraryManager
    @StateObject private var viewModel: ChapterListViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(manga: Manga, libraryManager: LibraryManager) {
        self.manga = manga
        self.libraryManager = libraryManager
        self._viewModel = StateObject(wrappedValue: ChapterListViewModel(mangaId: manga.id))
    }
    
    private var formattedTags: [String] {
        manga.attributes.tags
            .filter { $0.attributes.group == "genre" }
            .compactMap { $0.attributes.name["en"] }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover and Title Section
                HStack(alignment: .top, spacing: 16) {
                    CoverImageView(manga: manga, width: 120, height: 180)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(manga.attributes.title["en"] ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let rating = manga.attributes.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                        }
                        
                        Text("Status: \(manga.attributes.status.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let year = manga.attributes.year {
                            Text("Year: \(year)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        LibraryButton(libraryManager: libraryManager, manga: manga)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                // Tags Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8, data: formattedTags.indices.map { TagItem(id: formattedTags[$0], text: formattedTags[$0]) }) { item in
                        Text(item.text)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.horizontal)
                
                // Description Section
                if let description = manga.attributes.description["en"], !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                }
                
                // Chapters Section
                VStack(spacing: 16) {
                                   TextField("Search chapters...", text: $viewModel.searchText)
                                       .textFieldStyle(RoundedBorderTextFieldStyle())
                                       .padding(.horizontal)
                                   
                                   Picker("Sort Order", selection: $viewModel.sortOrder) {
                                       Text("Newest First").tag(ChapterListViewModel.SortOrder.desc)
                                       Text("Oldest First").tag(ChapterListViewModel.SortOrder.asc)
                                   }
                                   .pickerStyle(SegmentedPickerStyle())
                                   .padding(.horizontal)
                               }
                               .padding(.top)
                               
                               // Chapters List
                               VStack(alignment: .leading, spacing: 8) {
                                   Text("Chapters")
                                       .font(.headline)
                                       .padding(.horizontal)
                                   
                                   if viewModel.isLoading && viewModel.chapters.isEmpty {
                                       ProgressView()
                                           .frame(maxWidth: .infinity)
                                           .padding()
                                   } else if viewModel.chapters.isEmpty {
                                       Text("No chapters found")
                                           .frame(maxWidth: .infinity)
                                           .padding()
                                           .foregroundColor(.secondary)
                                   } else {
                                       LazyVStack(spacing: 0) {
                                           ForEach(viewModel.chapters) { chapter in
                                               NavigationLink(destination: PagedChapterReaderView(chapter: chapter)) {
                                                   ChapterRowView(chapter: chapter)
                                                       .padding(.horizontal)
                                                       .padding(.vertical, 8)
                                               }
                                               Divider()
                                           }
                                           
                                           if viewModel.hasMoreChapters {
                                               ProgressView()
                                                   .frame(maxWidth: .infinity)
                                                   .padding()
                                                   .onAppear {
                                                       Task {
                                                           await viewModel.loadChapters()
                                                       }
                                                   }
                                           }
                                       }
                                   }
                               }
                           }
                       }
                       .navigationBarTitleDisplayMode(.inline)
                       .task {
                           await viewModel.resetAndLoadChapters()
                       }
                       .refreshable {
                           await viewModel.resetAndLoadChapters()
                       }
                   }
               }
