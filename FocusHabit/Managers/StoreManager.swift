import StoreKit
import SwiftUI

@Observable
@MainActor
final class StoreManager {
    static let shared = StoreManager()

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    let lifetimeID = "com.a1111.FocusHabit.premium.lifetime2"

    private nonisolated(unsafe) var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
    }

    nonisolated deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: [lifetimeID])
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await checkEntitlements()
                case .unverified:
                    errorMessage = T("Purchase verification failed. Please try again.")
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        // 非消耗型内购的购买记录会自动出现在 Transaction.currentEntitlements 中，
        // 无需调用 AppStore.sync() 弹窗验证 Apple 账户。
        await checkEntitlements()
        isLoading = false
    }

    func checkEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == lifetimeID,
               transaction.revocationDate == nil {
                premium = true
                break
            }
        }
        isPremium = premium
    }

    // Feature gates
    var maxFreeHabits: Int { 3 }
    var canUnlimitedHabits: Bool { isPremium }
    var canCustomPresets: Bool { isPremium }
    var canReports: Bool { isPremium }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkEntitlements()
                }
            }
        }
    }
}
