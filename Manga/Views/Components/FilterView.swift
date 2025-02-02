import Foundation
import SwiftUI
import UIKit

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MangaListViewModel
    @State private var yearString: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    ClearableTextField(
                        placeholder: "Manga Title",
                        text: $viewModel.filter.titleSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                    
                    ClearableTextField(
                        placeholder: "Author Name",
                        text: $viewModel.filter.authorSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                    
                    ClearableTextField(
                        placeholder: "Artist Name",
                        text: $viewModel.filter.artistSearch,
                        onEditingChanged: { isEditing in
                            if !isEditing {
                                viewModel.handleSearchUpdate()
                            }
                        }
                    )
                }
                
                // Rest of the existing sections...
                Section(header: Text("Sort By")) {
                    Picker("Sort Option", selection: $viewModel.filter.sortOption) {
                        ForEach(MangaListViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Content Rating")) {
                    Picker("Content Rating", selection: $viewModel.filter.contentRating) {
                        Text("Any").tag(nil as ContentRating?)
                        ForEach(ContentRating.allCases, id: \.self) { rating in
                            Text(rating.displayName).tag(rating as ContentRating?)
                        }
                    }
                }
                
                Section(header: Text("Demographics")) {
                    Picker("Demographics", selection: $viewModel.filter.selectedDemographic) {
                        Text("Any").tag(nil as PublicationDemographic?)
                        ForEach(PublicationDemographic.allCases, id: \.self) { demographic in
                            Text(demographic.displayName).tag(demographic as PublicationDemographic?)
                        }
                    }
                }
                
                Section(header: Text("Publication Year")) {
                    TextField("Year (e.g., 2020)", text: $yearString)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Tags").textCase(.none)) {
                    TagFilterView(viewModel: viewModel)
                        .frame(minHeight: UIScreen.main.bounds.height * 1)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Apply") {
                if let year = Int(yearString) {
                    viewModel.filter.publicationYear = year
                } else {
                    viewModel.filter.publicationYear = nil
                }
                
                presentationMode.wrappedValue.dismiss()
                Task {
                    await viewModel.reloadData()
                }
            })
        }
    }
}
