import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WorkoutTracker")
        
        // Configure for CloudKit if available
        configurePersistentStore(container)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        // Configure automatic merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    
    private func configurePersistentStore(_ container: NSPersistentContainer) {
        // Configure store for optimal CloudKit sync
        guard let storeDescription = container.persistentStoreDescriptions.first else { return }
        
        // Enable persistent history tracking for CloudKit sync
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Configure for better performance
        storeDescription.setOption(["journal_mode": "WAL"] as NSDictionary, forKey: NSSQLitePragmasOption)
    }
    
    func save() {
        save(context: context)
    }
    
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - CloudKit Sync Support
    
    func fetchChangedObjects(since date: Date?) -> [NSManagedObject] {
        // TODO: Re-implement when CloudSyncable protocol is re-enabled
        return []
    }
    
    func markAllForCloudSync() {
        // TODO: Re-implement when CloudSyncable protocol is re-enabled
    }
    
    private init() {
        // Set up persistent history tracking
        setupPersistentHistoryTracking()
    }
    
    private func setupPersistentHistoryTracking() {
        // Listen for remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }
    
    @objc private func storeDidChange(_ notification: Notification) {
        // Handle remote changes from CloudKit
        DispatchQueue.main.async {
            self.context.refreshAllObjects()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}