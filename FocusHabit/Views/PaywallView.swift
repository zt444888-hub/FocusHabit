import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = StoreManager.shared
    @State private var selectedProduct: Product?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.brand)

                        Text(verbatim: T("FocusHabit Premium"))
                            .font(.title.weight(.bold))

                        Text(verbatim: T("Build habits that stick.\nUnlock the full experience."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Feature list
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "checklist", text: T("Unlimited habits (free: 3 max)"))
                        FeatureRow(icon: "timer", text: T("Custom timer presets"))
                        FeatureRow(icon: "chart.bar", text: T("Weekly reports & analytics"))
                        FeatureRow(icon: "xmark.circle", text: T("No ads, no tracking"))
                    }
                    .padding(.horizontal)

                    // Single lifetime purchase
                    VStack(spacing: 12) {
                            Button {
                                selectedProduct = store.products.first
                                if let product = store.products.first {
                                    Task { await store.purchase(product) }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: T("Lifetime Access"))
                                            .font(.headline)
                                        Text(verbatim: T("Pay once, use forever"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if store.isLoading && store.products.isEmpty {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(store.products.first?.displayPrice ?? "$2.99")
                                            .font(.title2.weight(.bold))
                                            .foregroundColor(.brand)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.background)
                                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brand.opacity(0.3), lineWidth: selectedProduct != nil ? 2 : 0)
                                )
                            }
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Restore + Loading
                    VStack(spacing: 8) {
                        if store.isLoading {
                            ProgressView()
                                .padding(.bottom, 4)
                        }

                        if let error = store.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button(T("Restore Purchases")) {
                            Task {
                                await store.restorePurchases()
                                restoreMessage = store.isPremium ? T("Premium restored!") : T("No purchase found to restore.")
                                showRestoreAlert = true
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }

                    // Already premium
                    if store.isPremium {
                        VStack(spacing: 8) {
                            Label(T("You're Premium!"), systemImage: "checkmark.seal.fill")
                                .foregroundColor(.brand)
                                .font(.headline)
                            Text(verbatim: T("Thanks for your support. You have lifetime access."))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(T("Upgrade"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(T("Close")) { dismiss() }
                }
            }
            .alert(T("Restore"), isPresented: $showRestoreAlert) {
                Button(T("OK")) { }
            } message: {
                Text(restoreMessage)
            }
            .task {
                await store.loadProducts()
                await store.checkEntitlements()
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brand)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
