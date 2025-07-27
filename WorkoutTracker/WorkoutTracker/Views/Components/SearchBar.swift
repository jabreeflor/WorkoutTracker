import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isEditing ? .primaryBlue : .secondary)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEditing)
            
            // Text field
            TextField("Search exercises...", text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .onTapGesture {
                    isEditing = true
                }
                .onSubmit {
                    isEditing = false
                }
                .onChange(of: text) { _, _ in
                    if !text.isEmpty {
                        isEditing = true
                    }
                }
            
            // Clear button
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isEditing = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: !text.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEditing ? Color.primaryBlue : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEditing)
    }
}

#Preview {
    SearchBar(text: .constant(""))
        .padding()
}