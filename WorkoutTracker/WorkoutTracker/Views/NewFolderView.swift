import SwiftUI

struct NewFolderView: View {
    @Environment(\.dismiss) private var dismiss
    let parentFolder: Folder?
    
    @State private var folderName = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder.fill"
    
    private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]
    private let icons = ["folder.fill", "dumbbell", "figure.strengthtraining.traditional", "heart.fill", "star.fill", "flame.fill"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Folder Name")
                        .font(.headline)
                    
                    TextField("Enter folder name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? Color(selectedColor) : .gray)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.gray.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: createFolder) {
                    Text("Create Folder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(folderName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(folderName.isEmpty)
            }
            .padding()
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createFolder() {
        let _ = TemplateService.shared.createFolder(
            name: folderName,
            color: selectedColor,
            icon: selectedIcon,
            parentFolder: parentFolder
        )
        dismiss()
    }
}

#Preview {
    NewFolderView(parentFolder: nil)
}