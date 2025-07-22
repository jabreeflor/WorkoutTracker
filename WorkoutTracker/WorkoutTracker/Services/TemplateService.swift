import CoreData
import Foundation

class TemplateService: ObservableObject {
    static let shared = TemplateService()
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    func createTemplateFromWorkout(_ workout: WorkoutSession, name: String? = nil, folder: Folder? = nil) -> WorkoutTemplate {
        let template = WorkoutTemplate(context: context)
        template.id = UUID()
        template.name = name ?? (workout.name ?? "Untitled Template")
        template.createdDate = Date()
        template.lastModifiedDate = Date()
        template.folder = folder
        template.defaultRestTime = 60
        
        if let workoutExercises = workout.exercises?.allObjects as? [WorkoutExercise] {
            for (index, workoutExercise) in workoutExercises.enumerated() {
                let templateExercise = TemplateExercise(context: context)
                templateExercise.id = UUID()
                templateExercise.exercise = workoutExercise.exercise
                templateExercise.template = template
                templateExercise.orderIndex = Int32(index)
                templateExercise.defaultSets = workoutExercise.sets
                templateExercise.defaultReps = workoutExercise.reps
                templateExercise.defaultWeight = workoutExercise.weight
                templateExercise.restTime = 60
            }
        }
        
        CoreDataManager.shared.save()
        return template
    }
    
    func createWorkoutFromTemplate(_ template: WorkoutTemplate) -> WorkoutSession {
        let workout = WorkoutSession(context: context)
        workout.id = UUID()
        workout.name = template.name
        workout.date = Date()
        workout.duration = 0
        
        if let templateExercises = template.templateExercises?.allObjects as? [TemplateExercise] {
            let sortedExercises = templateExercises.sorted { $0.orderIndex < $1.orderIndex }
            
            for templateExercise in sortedExercises {
                let workoutExercise = WorkoutExercise(context: context)
                workoutExercise.id = UUID()
                workoutExercise.exercise = templateExercise.exercise
                workoutExercise.workoutSession = workout
                workoutExercise.sets = templateExercise.defaultSets
                workoutExercise.reps = templateExercise.defaultReps
                workoutExercise.weight = templateExercise.defaultWeight
            }
        }
        
        return workout
    }
    
    func createFolder(name: String, color: String? = nil, icon: String? = nil, parentFolder: Folder? = nil) -> Folder {
        let folder = Folder(context: context)
        folder.id = UUID()
        folder.name = name
        folder.createdDate = Date()
        folder.color = color
        folder.icon = icon
        folder.parentFolder = parentFolder
        
        CoreDataManager.shared.save()
        return folder
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        context.delete(template)
        CoreDataManager.shared.save()
    }
    
    func deleteFolder(_ folder: Folder) {
        if let templates = folder.templates?.allObjects as? [WorkoutTemplate] {
            for template in templates {
                template.folder = nil
            }
        }
        
        if let subFolders = folder.subFolders?.allObjects as? [Folder] {
            for subFolder in subFolders {
                subFolder.parentFolder = folder.parentFolder
            }
        }
        
        context.delete(folder)
        CoreDataManager.shared.save()
    }
    
    func duplicateTemplate(_ template: WorkoutTemplate, newName: String? = nil) -> WorkoutTemplate {
        let newTemplate = WorkoutTemplate(context: context)
        newTemplate.id = UUID()
        newTemplate.name = newName ?? "\(template.name ?? "Template") Copy"
        newTemplate.createdDate = Date()
        newTemplate.lastModifiedDate = Date()
        newTemplate.folder = template.folder
        newTemplate.defaultRestTime = template.defaultRestTime
        newTemplate.notes = template.notes
        
        if let templateExercises = template.templateExercises?.allObjects as? [TemplateExercise] {
            for originalExercise in templateExercises {
                let newTemplateExercise = TemplateExercise(context: context)
                newTemplateExercise.id = UUID()
                newTemplateExercise.exercise = originalExercise.exercise
                newTemplateExercise.template = newTemplate
                newTemplateExercise.orderIndex = originalExercise.orderIndex
                newTemplateExercise.defaultSets = originalExercise.defaultSets
                newTemplateExercise.defaultReps = originalExercise.defaultReps
                newTemplateExercise.defaultWeight = originalExercise.defaultWeight
                newTemplateExercise.restTime = originalExercise.restTime
                newTemplateExercise.notes = originalExercise.notes
            }
        }
        
        CoreDataManager.shared.save()
        return newTemplate
    }
    
    func updateTemplate(_ template: WorkoutTemplate) {
        template.lastModifiedDate = Date()
        CoreDataManager.shared.save()
    }
    
    func moveTemplate(_ template: WorkoutTemplate, to folder: Folder?) {
        template.folder = folder
        updateTemplate(template)
    }
    
    func getDefaultFolder() -> Folder? {
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", "My Templates")
        
        do {
            let folders = try context.fetch(fetchRequest)
            if let defaultFolder = folders.first {
                return defaultFolder
            } else {
                return createFolder(name: "My Templates", color: "blue", icon: "folder.fill")
            }
        } catch {
            print("Error fetching default folder: \(error)")
            return nil
        }
    }
}