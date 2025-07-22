import SwiftUI
import StoreKit

struct PremiumPurchaseView: View {
    @StateObject private var premiumService = PremiumSubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Featured Benefits
                    benefitsSection
                    
                    // Pricing Options
                    if !premiumService.availableProducts.isEmpty {
                        pricingSection
                    } else {
                        loadingSection
                    }
                    
                    // Purchase Button
                    if let selectedProduct = selectedProduct {
                        purchaseButton(selectedProduct)
                    }
                    
                    // Restore Purchases
                    restorePurchasesButton
                    
                    // Terms and Privacy
                    termsSection
                }
                .padding()
            }
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await premiumService.initialize()
            if !premiumService.availableProducts.isEmpty {
                selectedProduct = premiumService.availableProducts.first
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Unlock Your Full Potential")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get AI-powered coaching, advanced analytics, and all premium features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                benefitCard(
                    icon: "brain.head.profile",
                    title: "AI Personal Coach",
                    description: "Personalized insights and recommendations",
                    color: .blue
                )
                
                benefitCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Deep performance analysis and trends",
                    color: .green
                )
                
                benefitCard(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    description: "Access your data on all devices",
                    color: .purple
                )
                
                benefitCard(
                    icon: "person.2.fill",
                    title: "Social Features",
                    description: "Share workouts and compete with friends",
                    color: .red
                )
                
                benefitCard(
                    icon: "doc.badge.plus",
                    title: "Unlimited Templates",
                    description: "Create custom workout routines",
                    color: .orange
                )
                
                benefitCard(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    description: "Download your workout history",
                    color: .teal
                )
            }
        }
    }
    
    private func benefitCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(premiumService.availableProducts, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }
    
    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let productID = PremiumSubscriptionService.ProductID(rawValue: product.id)
        
        return Button(action: {
            selectedProduct = product
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(productID?.displayName ?? product.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(productID?.description ?? product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if product.id.contains("yearly") {
                        Text("Save 20% compared to monthly")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if product.subscription != nil {
                        let period = product.id.contains("yearly") ? "year" : "month"
                        Text("per \(period)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Purchase Button
    
    private func purchaseButton(_ product: Product) -> some View {
        Button(action: {
            Task {
                await purchaseProduct(product)
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(isPurchasing ? "Processing..." : "Start Premium")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(isPurchasing || premiumService.isLoading)
    }
    
    // MARK: - Restore Purchases Button
    
    private var restorePurchasesButton: some View {
        Button("Restore Purchases") {
            Task {
                await premiumService.restorePurchases()
            }
        }
        .foregroundColor(.blue)
        .disabled(premiumService.isLoading)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By purchasing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    // Open terms URL
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading pricing options...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Helper Methods
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        do {
            try await premiumService.purchase(product)
            // Purchase successful - dismiss view
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isPurchasing = false
    }
}

#Preview {
    PremiumPurchaseView()
}