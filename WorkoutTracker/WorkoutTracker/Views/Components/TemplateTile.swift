import SwiftUI

struct TemplateTile: View {
    let template: WorkoutTemplate
    let action: () -> Void
    @State private var showingMenu = false
    
    private var exerciseCount: Int {
        template.templateExercises?.count ?? 0
    }
    
    private var previewExercises: String {
        guard let exercises = template.templateExercises?.allObjects as? [TemplateExercise] else {
            return "No exercises"
        }
        
        let sortedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
        let exerciseNames = sortedExercises.prefix(3).compactMap { $0.exercise?.name }
        
        if exerciseNames.isEmpty {
            return "No exercises"
        } else if exerciseNames.count < 3 {
            return exerciseNames.joined(separator: ", ")
        } else {
            return exerciseNames.joined(separator: ", ") + "..."
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name ?? "Untitled Template")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(exerciseCount) exercises")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingMenu = true
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                                .padding(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text(previewExercises)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let date = template.lastModifiedDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .actionSheet(isPresented: $showingMenu) {
            ActionSheet(
                title: Text(template.name ?? "Template"),
                buttons: [
                    .default(Text("Start Workout")) {
                        action()
                    },
                    .default(Text("Duplicate")) {
                        duplicateTemplate()
                    },
                    .destructive(Text("Delete")) {
                        deleteTemplate()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func duplicateTemplate() {
        let _ = TemplateService.shared.duplicateTemplate(template)
    }
    
    private func deleteTemplate() {
        TemplateService.shared.deleteTemplate(template)
    }
}

#Preview {
    let template = WorkoutTemplate()
    template.name = "Push Day Workout"
    
    return TemplateTile(template: template) {
        print("Template tapped")
    }
    .frame(width: 180)
}