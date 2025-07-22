import CoreData
import Foundation

class DataSeedingService {
    static let shared = DataSeedingService()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    func seedExerciseDatabase() {
        let exerciseData = [
            ("Push-ups", "Chest", "Triceps", "Bodyweight", "Beginner"),
            ("Pull-ups", "Back", "Biceps", "Bodyweight", "Intermediate"),
            ("Squats", "Quadriceps", "Glutes", "Bodyweight", "Beginner"),
            ("Lunges", "Quadriceps", "Glutes", "Bodyweight", "Beginner"),
            ("Plank", "Core", "Shoulders", "Bodyweight", "Beginner"),
            ("Burpees", "Full Body", "Cardiovascular", "Bodyweight", "Intermediate"),
            ("Mountain Climbers", "Core", "Shoulders", "Bodyweight", "Beginner"),
            ("Jumping Jacks", "Cardiovascular", "Full Body", "Bodyweight", "Beginner"),
            ("Bench Press", "Chest", "Triceps", "Barbell", "Intermediate"),
            ("Deadlift", "Back", "Hamstrings", "Barbell", "Intermediate"),
            ("Squat", "Quadriceps", "Glutes", "Barbell", "Intermediate"),
            ("Overhead Press", "Shoulders", "Triceps", "Barbell", "Intermediate"),
            ("Barbell Row", "Back", "Biceps", "Barbell", "Intermediate"),
            ("Bicep Curls", "Biceps", "Forearms", "Dumbbell", "Beginner"),
            ("Tricep Dips", "Triceps", "Shoulders", "Bodyweight", "Beginner"),
            ("Shoulder Press", "Shoulders", "Triceps", "Dumbbell", "Beginner"),
            ("Lateral Raises", "Shoulders", "Upper Back", "Dumbbell", "Beginner"),
            ("Chest Flyes", "Chest", "Shoulders", "Dumbbell", "Beginner"),
            ("Russian Twists", "Core", "Obliques", "Bodyweight", "Beginner"),
            ("Leg Press", "Quadriceps", "Glutes", "Machine", "Beginner"),
            ("Leg Curls", "Hamstrings", "Glutes", "Machine", "Beginner"),
            ("Calf Raises", "Calves", "Ankles", "Bodyweight", "Beginner"),
            ("Hip Thrusts", "Glutes", "Hamstrings", "Bodyweight", "Beginner"),
            ("Romanian Deadlift", "Hamstrings", "Glutes", "Barbell", "Intermediate"),
            ("Incline Bench Press", "Upper Chest", "Triceps", "Barbell", "Intermediate"),
            ("Decline Bench Press", "Lower Chest", "Triceps", "Barbell", "Intermediate"),
            ("Pull-downs", "Back", "Biceps", "Cable", "Beginner"),
            ("Cable Rows", "Back", "Biceps", "Cable", "Beginner"),
            ("Face Pulls", "Rear Delts", "Upper Back", "Cable", "Beginner"),
            ("Tricep Pushdowns", "Triceps", "Forearms", "Cable", "Beginner"),
            ("Hammer Curls", "Biceps", "Forearms", "Dumbbell", "Beginner"),
            ("Goblet Squats", "Quadriceps", "Glutes", "Dumbbell", "Beginner"),
            ("Walking Lunges", "Quadriceps", "Glutes", "Bodyweight", "Beginner"),
            ("Step-ups", "Quadriceps", "Glutes", "Bodyweight", "Beginner"),
            ("Wall Sits", "Quadriceps", "Glutes", "Bodyweight", "Beginner"),
            ("Glute Bridges", "Glutes", "Hamstrings", "Bodyweight", "Beginner"),
            ("Superman", "Lower Back", "Glutes", "Bodyweight", "Beginner"),
            ("Bird Dog", "Core", "Lower Back", "Bodyweight", "Beginner"),
            ("Dead Bug", "Core", "Hip Flexors", "Bodyweight", "Beginner"),
            ("High Knees", "Cardiovascular", "Hip Flexors", "Bodyweight", "Beginner"),
            ("Butt Kickers", "Cardiovascular", "Hamstrings", "Bodyweight", "Beginner"),
            ("Arm Circles", "Shoulders", "Arms", "Bodyweight", "Beginner"),
            ("Leg Swings", "Hip Flexors", "Hamstrings", "Bodyweight", "Beginner"),
            ("Chest Stretch", "Chest", "Shoulders", "Bodyweight", "Beginner"),
            ("Quad Stretch", "Quadriceps", "Hip Flexors", "Bodyweight", "Beginner"),
            ("Hamstring Stretch", "Hamstrings", "Calves", "Bodyweight", "Beginner"),
            ("Shoulder Stretch", "Shoulders", "Upper Back", "Bodyweight", "Beginner"),
            ("Cat-Cow Stretch", "Spine", "Core", "Bodyweight", "Beginner"),
            ("Child's Pose", "Back", "Shoulders", "Bodyweight", "Beginner"),
            ("Downward Dog", "Hamstrings", "Shoulders", "Bodyweight", "Beginner")
        ]
        
        for (name, primary, secondary, equipment, difficulty) in exerciseData {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = name
            exercise.primaryMuscleGroup = primary
            exercise.secondaryMuscleGroup = secondary
            exercise.equipment = equipment
            exercise.difficulty = difficulty
        }
        
        CoreDataManager.shared.save()
    }
    
    func checkAndSeedDatabase() {
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        do {
            let existingExercises = try context.fetch(fetchRequest)
            if existingExercises.isEmpty {
                seedExerciseDatabase()
            }
        } catch {
            print("Error checking existing exercises: \(error)")
        }
        
        checkAndSeedDefaultFolders()
    }
    
    private func checkAndSeedDefaultFolders() {
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        do {
            let existingFolders = try context.fetch(fetchRequest)
            if existingFolders.isEmpty {
                seedDefaultFolders()
            }
        } catch {
            print("Error checking existing folders: \(error)")
        }
    }
    
    private func seedDefaultFolders() {
        let defaultFolders = [
            ("My Templates", "blue", "folder.fill"),
            ("Push Workouts", "red", "dumbbell"),
            ("Pull Workouts", "green", "figure.strengthtraining.traditional"),
            ("Leg Workouts", "orange", "flame.fill")
        ]
        
        for (name, color, icon) in defaultFolders {
            let folder = Folder(context: context)
            folder.id = UUID()
            folder.name = name
            folder.color = color
            folder.icon = icon
            folder.createdDate = Date()
        }
        
        CoreDataManager.shared.save()
    }
}