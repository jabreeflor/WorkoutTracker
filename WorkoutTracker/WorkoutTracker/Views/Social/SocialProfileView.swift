import SwiftUI

struct SocialProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Social Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Social features coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
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
    SocialProfileView()
}