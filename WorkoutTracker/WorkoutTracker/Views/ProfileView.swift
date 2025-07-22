import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdDate, ascending: true)],
        animation: .default
    ) private var userProfiles: FetchedResults<UserProfile>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)],
        animation: .default
    ) private var workoutSessions: FetchedResults<WorkoutSession>
    
    @State private var userName = ""
    @State private var isEditingName = false
    @State private var showingSettings = false
    
    var userProfile: UserProfile {
        if let profile = userProfiles.first {
            return profile
        } else {
            let newProfile = UserProfile(context: viewContext)
            newProfile.id = UUID()
            newProfile.name = "Your Name"
            newProfile.workoutCount = 0
            newProfile.createdDate = Date()
            try? viewContext.save()
            return newProfile
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        if isEditingName {
                            TextField("Enter your name", text: $userName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .onSubmit {
                                    saveUserName()
                                }
                        } else {
                            Button(action: {
                                userName = userProfile.name ?? "Your Name"
                                isEditingName = true
                            }) {
                                Text(userProfile.name ?? "Your Name")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding()
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stats")
                            .font(.headline)
                            .bold()
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total Workouts",
                                value: "\(workoutSessions.count)",
                                icon: "dumbbell",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "This Week",
                                value: "\(workoutsThisWeek)",
                                icon: "calendar",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Total Time",
                                value: formatTotalTime(),
                                icon: "clock",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Avg Duration",
                                value: formatAverageTime(),
                                icon: "timer",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    
                    // Analytics Button
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insights")
                            .font(.headline)
                            .bold()
                        
                        NavigationLink(destination: WorkoutAnalyticsView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workout Analytics")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.primary)
                                    
                                    Text("View detailed progress charts and insights")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    
                    // Recent Activity
                    if !workoutSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Activity")
                                .font(.headline)
                                .bold()
                            
                            ForEach(Array(workoutSessions.prefix(3)), id: \.id) { workout in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(workout.name ?? "Unnamed Workout")
                                            .font(.subheadline)
                                            .bold()
                                        Text(workout.date ?? Date(), style: .date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(formatDuration(workout.duration))
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("\(workout.exercises?.count ?? 0) exercises")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                    }
                }
                
                if isEditingName {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            saveUserName()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ModernSettingsView()
            }
        }
    }
    
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return workoutSessions.filter { workout in
            guard let workoutDate = workout.date else { return false }
            return workoutDate >= weekStart
        }.count
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = workoutSessions.reduce(0) { $0 + Int($1.duration) }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatAverageTime() -> String {
        guard !workoutSessions.isEmpty else { return "0m" }
        
        let totalSeconds = workoutSessions.reduce(0) { $0 + Int($1.duration) }
        let averageSeconds = totalSeconds / workoutSessions.count
        let minutes = averageSeconds / 60
        
        return "\(minutes)m"
    }
    
    private func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func saveUserName() {
        userProfile.name = userName
        try? viewContext.save()
        isEditingName = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ProfileView()
}