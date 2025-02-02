import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: MangaListViewModel
    @ObservedObject var authManager: AuthenticationManager
    @StateObject var libraryManager: LibraryManager
    @State private var searchText = ""
    @State private var showingFilters = false
    
    init(viewModel: MangaListViewModel,
         authManager: AuthenticationManager) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.authManager = authManager
        _libraryManager = StateObject(wrappedValue: LibraryManager(authManager: authManager))
    }
    
    var body: some View {
        // The NavigationView wraps our entire tab structure
        NavigationView {
            // ZStack ensures proper layering of our background and content
            ZStack {
                // Background color extends to edges
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Main tab view containing all our content
                TabView {
                    // Browse Tab
                    BrowseTabView(
                        viewModel: viewModel,
                        libraryManager: libraryManager,
                        searchText: $searchText,
                        showingFilters: $showingFilters
                    )
                    .tabItem {
                        Label("Browse", systemImage: "book")
                    }
                    
                    // Library Tab
                    LibraryView(libraryManager: libraryManager, authManager: authManager)
                        .tabItem {
                            Label("Library", systemImage: "books.vertical")
                        }
                    
                    // Login Tab
                    LoginView()
                        .tabItem {
                            Label("Account", systemImage: "person.circle")
                        }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#Preview {
    ContentView(viewModel: MangaListViewModel(), authManager: AuthenticationManager())
}
