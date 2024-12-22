
import SwiftUI

@main
struct MangaApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var libraryManager: LibraryManager
    
    init() {
        // Create a temporary AuthenticationManager for initialization
        let tempAuthManager = AuthenticationManager()
        // Initialize libraryManager with the temporary manager
        _libraryManager = StateObject(wrappedValue: LibraryManager(authManager: tempAuthManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: MangaListViewModel(),
                authManager: authManager
            )
        }
    }
}
