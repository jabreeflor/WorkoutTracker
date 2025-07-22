import SwiftUI

struct FolderTile: View {
    let folder: Folder
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: folder.icon ?? "folder.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(folder.color ?? "blue"))
                
                Text(folder.name ?? "Untitled Folder")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(folder.templates?.count ?? 0) templates")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let folder = Folder()
    folder.name = "Push Day"
    folder.icon = "folder.fill"
    folder.color = "blue"
    
    return FolderTile(folder: folder) {
        print("Folder tapped")
    }
    .frame(width: 150)
}