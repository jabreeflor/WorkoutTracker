import Foundation
import StoreKit
import Combine

@MainActor
class PremiumSubscriptionService: ObservableObject {
    static let shared = PremiumSubscriptionService()
    
    // MARK: - Published Properties
    @Published var isSubscribed = false
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var availableProducts: [Product] = []
    @Published var purchaseError: String?
    @Published var isLoading = false
    
    // MARK: - Test Mode
    @Published var isTestModeEnabled = false {
        didSet {
            if isTestModeEnabled {
                subscriptionTier = .premium
                isSubscribed = true
                subscriptionStatus = .subscribed
                print("🧪 Premium Test Mode ENABLED - All premium features unlocked")
            } else {
                // Revert to actual subscription status
                Task {
                    await checkSubscriptionStatus()
                }
                print("🧪 Premium Test Mode DISABLED - Checking actual subscription")
            }
        }
    }
    
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case premiumMonthly = "com.workouttracker.premium.monthly"
        case premiumYearly = "com.workouttracker.premium.yearly"
        case premiumLifetime = "com.workouttracker.premium.lifetime"
        
        var displayName: String {
            switch self {
            case .premiumMonthly: return "Premium Monthly"
            case .premiumYearly: return "Premium Yearly"
            case .premiumLifetime: return "Premium Lifetime"
            }
        }
        
        var description: String {
            switch self {
            case .premiumMonthly: return "Full access to all premium features, billed monthly"
            case .premiumYearly: return "Full access to all premium features, billed yearly (save 20%)"
            case .premiumLifetime: return "One-time purchase for lifetime access to all premium features"
            }
        }
    }
    
    // MARK: - Subscription Tiers
    enum SubscriptionTier: String, CaseIterable {
        case free = "free"
        case premium = "premium"
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .premium: return "Premium"
            }
        }
        
        var features: [PremiumFeature] {
            switch self {
            case .free:
                return [.basicWorkouts, .basicAnalytics, .basicTemplates]
            case .premium:
                return PremiumFeature.allCases
            }
        }
    }
    
    // MARK: - Subscription Status
    enum SubscriptionStatus {
        case notSubscribed
        case subscribed
        case expired
        case inGracePeriod
        case inBillingRetryPeriod
        case revoked
        
        var description: String {
            switch self {
            case .notSubscribed: return "Not subscribed"
            case .subscribed: return "Active subscription"
            case .expired: return "Subscription expired"
            case .inGracePeriod: return "In grace period"
            case .inBillingRetryPeriod: return "Billing retry"
            case .revoked: return "Subscription revoked"
            }
        }
    }
    
    // MARK: - Premium Features
    enum PremiumFeature: String, CaseIterable {
        // Free features
        case basicWorkouts = "basic_workouts"
        case basicAnalytics = "basic_analytics"
        case basicTemplates = "basic_templates"
        
        // Premium features
        case aiCoach = "ai_coach"
        case advancedAnalytics = "advanced_analytics"
        case formAnalysis = "form_analysis"
        case cloudSync = "cloud_sync"
        case socialFeatures = "social_features"
        case unlimitedTemplates = "unlimited_templates"
        case exportData = "export_data"
        case customWorkouts = "custom_workouts"
        case nutritionTracking = "nutrition_tracking"
        case sleepTracking = "sleep_tracking"
        case heartRateIntegration = "heart_rate_integration"
        case personalizedRecommendations = "personalized_recommendations"
        
        var displayName: String {
            switch self {
            case .basicWorkouts: return "Basic Workouts"
            case .basicAnalytics: return "Basic Analytics"
            case .basicTemplates: return "Basic Templates"
            case .aiCoach: return "AI Personal Coach"
            case .advancedAnalytics: return "Advanced Analytics"
            case .formAnalysis: return "Form Analysis"
            case .cloudSync: return "Cloud Sync"
            case .socialFeatures: return "Social Features"
            case .unlimitedTemplates: return "Unlimited Templates"
            case .exportData: return "Export Data"
            case .customWorkouts: return "Custom Workouts"
            case .nutritionTracking: return "Nutrition Tracking"
            case .sleepTracking: return "Sleep Tracking"
            case .heartRateIntegration: return "Heart Rate Integration"
            case .personalizedRecommendations: return "Personalized Recommendations"
            }
        }
        
        var description: String {
            switch self {
            case .basicWorkouts: return "Track your workouts and exercises"
            case .basicAnalytics: return "View basic workout statistics"
            case .basicTemplates: return "Use pre-made workout templates"
            case .aiCoach: return "Get personalized coaching with AI-powered insights"
            case .advancedAnalytics: return "Deep dive into your performance with detailed analytics"
            case .formAnalysis: return "AI-powered form analysis and corrections"
            case .cloudSync: return "Sync your data across all devices"
            case .socialFeatures: return "Share workouts and follow friends"
            case .unlimitedTemplates: return "Create unlimited custom workout templates"
            case .exportData: return "Export your workout data"
            case .customWorkouts: return "Create fully customized workout routines"
            case .nutritionTracking: return "Track nutrition and meal planning"
            case .sleepTracking: return "Monitor sleep patterns and recovery"
            case .heartRateIntegration: return "Connect with heart rate monitors"
            case .personalizedRecommendations: return "Get AI-powered workout recommendations"
            }
        }
        
        var icon: String {
            switch self {
            case .basicWorkouts: return "dumbbell"
            case .basicAnalytics: return "chart.bar"
            case .basicTemplates: return "doc.text"
            case .aiCoach: return "brain.head.profile"
            case .advancedAnalytics: return "chart.line.uptrend.xyaxis"
            case .formAnalysis: return "camera.viewfinder"
            case .cloudSync: return "icloud"
            case .socialFeatures: return "person.2"
            case .unlimitedTemplates: return "doc.badge.plus"
            case .exportData: return "square.and.arrow.up"
            case .customWorkouts: return "slider.horizontal.3"
            case .nutritionTracking: return "leaf"
            case .sleepTracking: return "bed.double"
            case .heartRateIntegration: return "heart.pulse"
            case .personalizedRecommendations: return "lightbulb"
            }
        }
        
        var isPremium: Bool {
            return ![.basicWorkouts, .basicAnalytics, .basicTemplates].contains(self)
        }
    }
    
    private init() {
        startUpdateListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func initialize() async {
        await loadProducts()
        await checkSubscriptionStatus()
    }
    
    func hasFeature(_ feature: PremiumFeature) -> Bool {
        // Test mode overrides everything
        if isTestModeEnabled {
            return true
        }
        
        // Free features are always available
        if !feature.isPremium {
            return true
        }
        
        // Premium features require subscription
        return isSubscribed && subscriptionTier == .premium
    }
    
    func purchase(_ product: Product) async throws {
        guard !isTestModeEnabled else {
            print("🧪 Test mode enabled - purchase simulated")
            return
        }
        
        isLoading = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
                isLoading = false
                
            case .userCancelled:
                isLoading = false
                
            case .pending:
                isLoading = false
                
            @unknown default:
                isLoading = false
            }
        } catch {
            isLoading = false
            purchaseError = error.localizedDescription
            throw error
        }
    }
    
    func restorePurchases() async {
        guard !isTestModeEnabled else {
            print("🧪 Test mode enabled - restore simulated")
            return
        }
        
        isLoading = true
        
        try? await AppStore.sync()
        await checkSubscriptionStatus()
        
        isLoading = false
    }
    
    func enableTestMode() {
        isTestModeEnabled = true
    }
    
    func disableTestMode() {
        isTestModeEnabled = false
    }
    
    // MARK: - Private Methods
    
    private func loadProducts() async {
        do {
            availableProducts = try await Product.products(for: ProductID.allCases.map { $0.rawValue })
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    private func checkSubscriptionStatus() async {
        guard !isTestModeEnabled else { return }
        
        var hasValidSubscription = false
        var currentTier = SubscriptionTier.free
        var status = SubscriptionStatus.notSubscribed
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                let productID = ProductID(rawValue: transaction.productID)
                if productID != nil {
                    hasValidSubscription = true
                    currentTier = .premium
                    
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            status = .subscribed
                        } else {
                            status = .expired
                            hasValidSubscription = false
                            currentTier = .free
                        }
                    } else {
                        // Lifetime subscription
                        status = .subscribed
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        await MainActor.run {
            isSubscribed = hasValidSubscription
            subscriptionTier = currentTier
            subscriptionStatus = status
        }
    }
    
    private func startUpdateListener() {
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PremiumError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Premium Errors

enum PremiumError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

// MARK: - Convenience Extensions

extension PremiumSubscriptionService {
    var isPremium: Bool {
        return hasFeature(.aiCoach)
    }
    
    var canUseAICoach: Bool {
        return hasFeature(.aiCoach)
    }
    
    var canUseAdvancedAnalytics: Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    var canUseFormAnalysis: Bool {
        return hasFeature(.formAnalysis)
    }
    
    var canUseSocialFeatures: Bool {
        return hasFeature(.socialFeatures)
    }
    
    var canUseCloudSync: Bool {
        return hasFeature(.cloudSync)
    }
}