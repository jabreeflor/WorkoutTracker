import SwiftUI

struct PremiumFeaturesView: View {
    @StateObject private var premiumService = PremiumSubscriptionService.shared
    @StateObject private var aiCoach = AICoachService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingPurchaseSheet = false
    @State private var showingTestModeAlert = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Features Overview
                featuresOverviewTab
                    .tabItem {
                        Image(systemName: "crown.fill")
                        Text("Premium")
                    }
                    .tag(0)
                
                // AI Coach Tab
                aiCoachTab
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Coach")
                    }
                    .tag(1)
                
                // Analytics Tab
                advancedAnalyticsTab
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Settings Tab
                premiumSettingsTab
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .navigationTitle("Premium Features")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !premiumService.isSubscribed && !premiumService.isTestModeEnabled {
                        Button("Upgrade") {
                            showingPurchaseSheet = true
                        }
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPurchaseSheet) {
            PremiumPurchaseView()
        }
        .alert("Enable Test Mode?", isPresented: $showingTestModeAlert) {
            Button("Enable") {
                premiumService.enableTestMode()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will enable all premium features for testing purposes without purchasing a subscription.")
        }
    }
    
    // MARK: - Features Overview Tab
    
    private var featuresOverviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Premium Status Card
                premiumStatusCard
                
                // Feature Categories
                VStack(spacing: 16) {
                    featureCategoryCard(
                        title: "AI Personal Coach",
                        icon: "brain.head.profile",
                        color: .blue,
                        features: [
                            .aiCoach,
                            .personalizedRecommendations,
                            .formAnalysis
                        ]
                    )
                    
                    featureCategoryCard(
                        title: "Advanced Analytics",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        features: [
                            .advancedAnalytics,
                            .exportData
                        ]
                    )
                    
                    featureCategoryCard(
                        title: "Cloud & Social",
                        icon: "icloud.fill",
                        color: .purple,
                        features: [
                            .cloudSync,
                            .socialFeatures
                        ]
                    )
                    
                    featureCategoryCard(
                        title: "Enhanced Training",
                        icon: "dumbbell.fill",
                        color: .orange,
                        features: [
                            .unlimitedTemplates,
                            .customWorkouts,
                            .heartRateIntegration
                        ]
                    )
                    
                    featureCategoryCard(
                        title: "Health & Wellness",
                        icon: "heart.fill",
                        color: .red,
                        features: [
                            .nutritionTracking,
                            .sleepTracking
                        ]
                    )
                }
                
                // Test Mode Section (Debug)
                #if DEBUG
                testModeSection
                #endif
            }
            .padding()
        }
    }
    
    // MARK: - AI Coach Tab
    
    private var aiCoachTab: some View {
        Group {
            if premiumService.canUseAICoach {
                AICoachDashboardView()
            } else {
                featureLockedView(
                    title: "AI Personal Coach",
                    icon: "brain.head.profile",
                    description: "Get personalized workout recommendations, form analysis, and intelligent insights based on your training patterns.",
                    benefits: [
                        "Personalized workout recommendations",
                        "Performance trend analysis",
                        "Plateau detection and solutions",
                        "Recovery optimization",
                        "Progressive overload guidance"
                    ]
                )
            }
        }
    }
    
    // MARK: - Advanced Analytics Tab
    
    private var advancedAnalyticsTab: some View {
        Group {
            if premiumService.canUseAdvancedAnalytics {
                AdvancedAnalyticsView()
            } else {
                featureLockedView(
                    title: "Advanced Analytics",
                    icon: "chart.line.uptrend.xyaxis",
                    description: "Deep dive into your performance with detailed analytics, trends, and predictive insights.",
                    benefits: [
                        "Performance trend analysis",
                        "Muscle group balance tracking",
                        "Volume and intensity analytics",
                        "Progress predictions",
                        "Data export capabilities"
                    ]
                )
            }
        }
    }
    
    // MARK: - Premium Settings Tab
    
    private var premiumSettingsTab: some View {
        List {
            Section("Subscription") {
                if premiumService.isTestModeEnabled {
                    Label("Test Mode Active", systemImage: "testtube.2")
                        .foregroundColor(.orange)
                } else if premiumService.isSubscribed {
                    Label("Premium Active", systemImage: "crown.fill")
                        .foregroundColor(.orange)
                } else {
                    Label("Free Plan", systemImage: "person")
                        .foregroundColor(.secondary)
                }
                
                if premiumService.isSubscribed && !premiumService.isTestModeEnabled {
                    Button("Manage Subscription") {
                        // Open App Store subscription management
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if !premiumService.isSubscribed {
                    Button("Restore Purchases") {
                        Task {
                            await premiumService.restorePurchases()
                        }
                    }
                }
            }
            
            Section("Premium Features") {
                ForEach(PremiumSubscriptionService.PremiumFeature.allCases.filter(\.isPremium), id: \.rawValue) { feature in
                    HStack {
                        Image(systemName: feature.icon)
                            .foregroundColor(premiumService.hasFeature(feature) ? .green : .gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.displayName)
                                .font(.subheadline)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if premiumService.hasFeature(feature) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            #if DEBUG
            Section("Debug") {
                Button(premiumService.isTestModeEnabled ? "Disable Test Mode" : "Enable Test Mode") {
                    if premiumService.isTestModeEnabled {
                        premiumService.disableTestMode()
                    } else {
                        showingTestModeAlert = true
                    }
                }
                .foregroundColor(premiumService.isTestModeEnabled ? .red : .blue)
            }
            #endif
        }
    }
    
    // MARK: - Helper Views
    
    private var premiumStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: premiumService.isSubscribed || premiumService.isTestModeEnabled ? "crown.fill" : "crown")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(premiumService.isTestModeEnabled ? "Test Mode Active" : premiumService.subscriptionTier.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(premiumService.isTestModeEnabled ? "All features unlocked for testing" : premiumService.subscriptionStatus.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if !premiumService.isSubscribed && !premiumService.isTestModeEnabled {
                Button("Upgrade to Premium") {
                    showingPurchaseSheet = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func featureCategoryCard(title: String, icon: String, color: Color, features: [PremiumSubscriptionService.PremiumFeature]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(features, id: \.rawValue) { feature in
                    HStack {
                        Image(systemName: premiumService.hasFeature(feature) ? "checkmark.circle.fill" : "lock.circle.fill")
                            .foregroundColor(premiumService.hasFeature(feature) ? .green : .gray)
                        
                        Text(feature.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func featureLockedView(title: String, icon: String, description: String, benefits: [String]) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Premium Benefits:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(benefits, id: \.self) { benefit in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(benefit)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                Button("Upgrade to Premium") {
                    showingPurchaseSheet = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(12)
                
                #if DEBUG
                Button("Enable Test Mode") {
                    showingTestModeAlert = true
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                #endif
            }
            .padding()
        }
    }
    
    #if DEBUG
    private var testModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "testtube.2")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Developer Test Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Test all premium features without purchasing a subscription. This is only available in debug builds.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(premiumService.isTestModeEnabled ? "Disable Test Mode" : "Enable Test Mode") {
                if premiumService.isTestModeEnabled {
                    premiumService.disableTestMode()
                } else {
                    showingTestModeAlert = true
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(premiumService.isTestModeEnabled ? Color.red : Color.blue)
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    #endif
}

#Preview {
    PremiumFeaturesView()
}