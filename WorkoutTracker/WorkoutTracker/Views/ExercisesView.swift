import SwiftUI
import CoreData

struct ExercisesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)],
        animation: .default
    ) private var exercises: FetchedResults<Exercise>
    
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return Array(exercises)
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.primaryMuscleGroup?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List(filteredExercises, id: \.id) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name ?? "Unknown Exercise")
                            .font(.headline)
                        
                        HStack {
                            Text("Primary: \(exercise.primaryMuscleGroup ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(exercise.equipment ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let secondary = exercise.secondaryMuscleGroup, !secondary.isEmpty {
                            Text("Secondary: \(secondary)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Exercises")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

#Preview {
    ExercisesView()
}