# MangaDex iOS Client

A native iOS client for browsing and reading manga from MangaDex.org, built using SwiftUI.

## Features

- Browse MangaDex's manga catalog with advanced filtering options
- Read manga chapters with a fluid page viewer
- Track reading progress across chapters
- Personal library management with reading status tracking
- Follow your favorite manga and get updates
- Comprehensive search with filters for demographics, years, tags, and more
- Support for MangaDex authentication

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- A MangaDex account and API client credentials

## Setup

1. Clone the repository
2. Open the project in Xcode
3. Build and run the project

### Authentication Setup

To use the app, you'll need:

1. A MangaDex account (create one at [mangadex.org](https://mangadex.org))
2. API client credentials:
   - Go to [mangadex.org/settings](https://mangadex.org/settings)
   - Navigate to the API clients section
   - Create a new client
   - Save your Client ID and Client Secret

## Project Structure

```
MangaApp/
├── App/
│   └── MangaApp.swift       # Main app entry point
├── Models/
│   ├── Manga.swift          # Manga data models
│   ├── Chapter.swift        # Chapter data models
│   └── Tag.swift           # Tag and filtering models
├── Views/
│   ├── ContentView.swift    # Main tab view
│   ├── MangaDetailView.swift # Manga details
│   ├── ChapterReaderView.swift # Chapter reader
│   └── Components/         # Reusable view components
├── ViewModels/
│   ├── MangaListViewModel.swift # Browse manga
│   └── ChapterListViewModel.swift # Chapter list
└── Services/
    ├── MangaDexAPI.swift   # API communication
    ├── AuthManager.swift   # Authentication
    └── LibraryManager.swift # Library management
```

## Features Overview

### Browse
- Search manga by title
- Filter by demographics (shounen, shoujo, seinen, josei)
- Filter by tags (genres, themes, formats)
- Sort by various criteria (popularity, latest updates, etc.)
- View manga details including description, tags, and chapters

### Read
- Fluid page navigation
- Progress tracking
- Chapter list with scanlation group information
- Reading history

### Library
- Add manga to your library
- Track reading status (Reading, Completed, Plan to Read, etc.)
- Sync with MangaDex account
- View latest chapter updates for followed manga

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## API Documentation

This app uses the MangaDex API v5. For more information about the API, visit:
[api.mangadex.org/docs](https://api.mangadex.org/docs)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- MangaDex for providing the API
- The scanlation groups for their hard work
- The manga community

## Disclaimer

This is an unofficial client for MangaDex. Please support the official release and the content creators.