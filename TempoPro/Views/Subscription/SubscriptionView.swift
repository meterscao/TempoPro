//
//  SubscriptionView.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/14.
//


import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack {
            if subscriptionManager.isLoading {
                ProgressView()
            } else if subscriptionManager.purchaseSuccess || subscriptionManager.isProUser {
                // Success view
                PurchaseSuccessView {
                    dismiss()
                }
            } else {
                // Subscription UI
                SubscriptionOptionsView(offerings: subscriptionManager.offerings)
                    
            }
        }
        .onAppear {
            subscriptionManager.checkSubscriptionStatus()
            subscriptionManager.loadOfferings()
        }
    }
}

// Purchase Success View
struct PurchaseSuccessView: View {
    @Environment(\.metronomeTheme) var theme
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accent)
                .padding(.top, 40)
            
            Text("Purchase Successful!")
                .font(.custom("MiSansLatin-Semibold", size: 24))
                .foregroundColor(Color("textPrimaryColor"))
            
            Text("Thank you for becoming a Premium member!\nYou now have access to all premium features.")
                .font(.custom("MiSansLatin-Regular", size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("textSecondaryColor"))
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Get Started")
                    .font(.custom("MiSansLatin-Semibold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(Color("backgroundPrimaryColor"))
    }
}

struct SubscriptionOptionsView: View {
    @Environment(\.metronomeTheme) var theme
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let offerings: Offerings?
    @State private var selectedOption = 2 // Default to lifetime
    
    var body: some View {
        ListView {
            // Header
            VStack(spacing: 8) {
                PremiumLabelView()
                Text("Upgrade to Premium")
                    .font(.custom("MiSansLatin-Semibold", size: 24))
                    .foregroundColor(Color("textPrimaryColor"))
                
                Text("Unlock all premium features to enhance your practice experience")
                    .font(.custom("MiSansLatin-Regular", size: 14))
                    .foregroundColor(Color("textSecondaryColor"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top,30)
            .padding(.bottom, 20)
            
            // Metronome Features
            SectionView(header: "METRONOME FEATURES") {
                FeatureRow(text: "Subdivision Practice", description: "Practice with complex rhythm subdivisions to improve your timing")
                FeatureRow(text: "Progressive Practice", description: "Gradually increase tempo to build speed and confidence")
                FeatureRow(text: "Count Down Practice", description: "Set timer-based practice sessions for focused training")
                FeatureRow(text: "Premium Sound Effects", description: "Access a library of professional-grade metronome sounds")
            }
            
            // Library Features
            SectionView(header: "LIBRARY FEATURES") {
                FeatureRow(text: "Unlimited Library", description: "Save unlimited practice routines and custom settings")
                FeatureRow(text: "Cloud Sync", description: "Seamlessly access your practice library across all your devices")
            }
            
            // Practice Record Features
            SectionView(header: "PRACTICE ANALYTICS") {
                FeatureRow(text: "Detailed Practice Charts", description: "Track your progress with comprehensive analytics")
                FeatureRow(text: "Complete Practice Calendar", description: "View your entire practice history in a calendar format")
                FeatureRow(text: "Custom Practice Sessions", description: "Create specialized practice missions with goals and reminders")
            }
            
            // Style Features
            SectionView(header: "PERSONALIZATION") {
                FeatureRow(text: "Metronome Themes", description: "Customize the look and feel with exclusive premium themes")
                FeatureRow(text: "Custom App Icons", description: "Choose from a variety of app icons for your home screen")
            }
            
            // Purchase Option
            VStack(spacing: 16) {
                if let standardOffering = offerings?.current {
                    // Lifetime option
                    SubscriptionOption(
                        title: "Lifetime Premium",
                        price: standardOffering.lifetime?.localizedPriceString ?? "$??",
                        description: "One-time payment, lifetime access",
                        isSelected: selectedOption == 2,
                        action: { selectedOption = 2 }
                    )
                }
            }
            
            
            // Subscribe Button
            Button(action: {
                if let package = getSelectedPackage() {
                    subscriptionManager.purchasePackage(package: package)
                }
            }) {
                Text(subscriptionManager.isPurchasing ? "Processing..." : "Subscribe Now")
                    .font(.custom("MiSansLatin-Semibold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accent)
                    .cornerRadius(12)
            }
            .disabled(subscriptionManager.isPurchasing)
            
            // Footer Links
            HStack {
                HStack(spacing: 16) {
                    Button(action: {}){
                        Text("Terms of Use")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                    
                    Button(action: {}){
                        Text("Privacy Policy")
                            .font(.custom("MiSansLatin-Regular", size: 12))
                            .foregroundColor(Color("textSecondaryColor"))
                    }
                }
                Spacer()
                Button(action: {
                    subscriptionManager.restorePurchase()
                }) {
                    Text("Restore Purchase")
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(Color("textSecondaryColor"))
                }
            }
            
        }
    }
    
    // Helper method to get selected package
    private func getSelectedPackage() -> Package? {
        guard let offering = offerings?.current else { return nil }
        
        switch selectedOption {
        case 0:
            return offering.monthly
        case 1:
            return offering.annual
        case 2:
            return offering.lifetime
        default:
            return nil
        }
    }
}

// Feature row with description
struct FeatureRow: View {
    @Environment(\.metronomeTheme) var theme
    let text: String
    let description: String
    
    var body: some View {
            HStack(spacing: 12) {
                Image("icon-check-s")
                    .renderingMode(.template)
                    .foregroundColor(.accent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(text)
                        .font(.custom("MiSansLatin-Regular", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if false && !description.isEmpty {
                        Text(description)
                            .font(.custom("MiSansLatin-Regular", size: 13))
                            .foregroundColor(Color("textSecondaryColor"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(alignment:.top)
    }
}

struct SubscriptionOption: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.custom("MiSansLatin-Semibold", size: 16))
                        .foregroundColor(Color("textPrimaryColor"))
                    
                    Text(price)
                        .font(.custom("MiSansLatin-Semibold", size: 22))
                        .foregroundColor(.accent)
                    
                    Text(description)
                        .font(.custom("MiSansLatin-Regular", size: 12))
                        .foregroundColor(Color("textSecondaryColor"))
                }
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accent)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accent : Color("textSecondaryColor").opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .padding(1)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("backgroundSecondaryColor"))
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

