import SwiftUI

struct UserDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("User Discovery")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Find and connect with other users!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Coming soon...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserDiscoveryView()
}