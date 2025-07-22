//
//  ContentView.swift
//  WorkoutTracker
//
//  Created by Jabree Flor on 7/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingIconGenerator = false
    
    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            
            WorkoutView()
                .tabItem {
                    Image(systemName: "dumbbell")
                    Text("Workout")
                }
            
            ExercisesView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Exercises")
                }
            
            InsightsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Insights")
                }
        }
        .sheet(isPresented: $showingIconGenerator) {
            IconGeneratorView()
        }
    }
}

#Preview {
    ContentView()
}
