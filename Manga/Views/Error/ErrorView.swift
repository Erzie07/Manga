import SwiftUI
import Foundation

struct ErrorView: View {
    let error: Error
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error loading chapter")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Go Back") {
                onDismiss()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
    }
}
