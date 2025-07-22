import SwiftUI

struct ModernAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCredits = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // App Header
                    appHeaderSection
                    
                    // Features Section
                    featuresSection
                    
                    // AI Features Section
                    aiFeatureSection
                    
                    // What's New Section
                    whatsNewSection
                    
                    // Links Section
                    linksSection
                    
                    // Legal Section
                    legalSection
                    
                    // Credits Section
                    creditsSection
                }
                .padding()
                .padding(.bottom, 50)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCredits) {
                CreditsView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                WebView(url: "https://workouttracker.app/privacy")
            }
            .sheet(isPresented: $showingTermsOfService) {
                WebView(url: "https://workouttracker.app/terms")
            }
        }
    }
    
    // MARK: - App Header Section
    
    private var appHeaderSection: some View {
        VStack(spacing: 20) {
            // App Icon
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("WorkoutTracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("AI-Powered Fitness Tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    InfoChip(text: "Version 1.0.0", icon: "number")
                    InfoChip(text: "iOS 17+", icon: "iphone")
                }
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Features")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                FeatureCard(
                    icon: "dumbbell.fill",
                    title: "Workout Tracking",
                    description: "Log sets, reps, and weights with precision",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "folder.fill",
                    title: "Smart Templates",
                    description: "Organize workouts with custom templates",
                    color: .green
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Analytics",
                    description: "Track your strength gains over time",
                    color: .orange
                )
                
                FeatureCard(
                    icon: "timer",
                    title: "Rest Timers",
                    description: "Built-in timers with haptic feedback",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - AI Features Section
    
    private var aiFeatureSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.indigo)
                    .font(.title2)
                
                Text("AI Intelligence")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                AIFeatureRow(
                    icon: "crystal.ball.fill",
                    title: "Performance Predictions",
                    description: "AI predicts your next workout performance with 85%+ accuracy",
                    color: .indigo
                )
                
                AIFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progression Timelines",
                    description: "See when you'll reach your strength goals based on current progress",
                    color: .blue
                )
                
                AIFeatureRow(
                    icon: "lightbulb.fill",
                    title: "Smart Recommendations",
                    description: "Get personalized exercise and programming suggestions",
                    color: .yellow
                )
                
                AIFeatureRow(
                    icon: "scale.3d",
                    title: "Exercise Comparisons",
                    description: "Compare similar exercises to optimize your routine",
                    color: .green
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - What's New Section
    
    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's New in 1.0")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                WhatsNewRow(
                    version: "1.0.0",
                    title: "AI Insights Tab",
                    description: "Brand new AI-powered insights dashboard with performance predictions",
                    isNew: true
                )
                
                WhatsNewRow(
                    version: "1.0.0",
                    title: "Smart Recommendations",
                    description: "Get personalized workout suggestions based on your training history",
                    isNew: true
                )
                
                WhatsNewRow(
                    version: "1.0.0",
                    title: "Enhanced Analytics",
                    description: "Deep dive into your performance with advanced charts and trends",
                    isNew: false
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Links Section
    
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connect & Support")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                LinkRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Get help with any questions",
                    color: .blue
                ) {
                    contactSupport()
                }
                
                LinkRow(
                    icon: "star.fill",
                    title: "Rate on App Store",
                    subtitle: "Help others discover WorkoutTracker",
                    color: .yellow
                ) {
                    rateApp()
                }
                
                LinkRow(
                    icon: "globe",
                    title: "Visit Website",
                    subtitle: "Learn more at workouttracker.app",
                    color: .green
                ) {
                    openWebsite()
                }
                
                LinkRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Join Community",
                    subtitle: "Connect with other fitness enthusiasts",
                    color: .purple
                ) {
                    joinCommunity()
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Legal")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                LinkRow(
                    icon: "doc.text.fill",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    color: .gray
                ) {
                    showingPrivacyPolicy = true
                }
                
                LinkRow(
                    icon: "doc.plaintext.fill",
                    title: "Terms of Service",
                    subtitle: "Terms and conditions of use",
                    color: .gray
                ) {
                    showingTermsOfService = true
                }
                
                LinkRow(
                    icon: "building.2.fill",
                    title: "Open Source Licenses",
                    subtitle: "Third-party library acknowledgments",
                    color: .gray
                ) {
                    showingCredits = true
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(spacing: 16) {
            Text("Made with 💪 for fitness enthusiasts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("© 2024 WorkoutTracker. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Action Functions
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@workouttracker.app?subject=WorkoutTracker Support") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://workouttracker.app") {
            UIApplication.shared.open(url)
        }
    }
    
    private func joinCommunity() {
        if let url = URL(string: "https://discord.gg/workouttracker") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct InfoChip: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct WhatsNewRow: View {
    let version: String
    let title: String
    let description: String
    let isNew: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 4) {
                if isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                } else {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Open Source Libraries")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        CreditRow(
                            name: "SwiftUI",
                            description: "Apple's declarative UI framework",
                            license: "Apple Software License"
                        )
                        
                        CreditRow(
                            name: "Core Data",
                            description: "Apple's object graph and persistence framework",
                            license: "Apple Software License"
                        )
                        
                        CreditRow(
                            name: "Core ML",
                            description: "Apple's machine learning framework",
                            license: "Apple Software License"
                        )
                    }
                    
                    Text("Special Thanks")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Thanks to the fitness community for feedback and inspiration, and to all beta testers who helped make WorkoutTracker better.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreditRow: View {
    let name: String
    let description: String
    let license: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(license)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct WebView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("This would show web content for: \(url)")
                    .padding()
                Spacer()
            }
            .navigationTitle("Web View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ModernAboutView()
}