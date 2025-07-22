//
//  WorkoutTrackerApp.swift
//  WorkoutTracker
//
//  Created by Jabree Flor on 7/6/25.
//

import SwiftUI

@main
struct WorkoutTrackerApp: App {
    let coreDataManager = CoreDataManager.shared
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    
    init() {
        // Data seeding will happen after Core Data is initialized
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.context)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // Seed database after the app is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        DataSeedingService.shared.checkAndSeedDatabase()
                    }
                }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch preferredColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // Uses system setting
        }
    }
}
