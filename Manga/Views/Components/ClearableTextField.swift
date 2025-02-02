import Foundation
import UIKit
import SwiftUI


struct ClearableTextField: View {
    let placeholder: String
    @Binding var text: String
    let onEditingChanged: (Bool) -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onEditingChanged(false)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
