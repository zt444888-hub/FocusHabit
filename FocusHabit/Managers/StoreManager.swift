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
    /// 历史产品 ID 兼容：若 1.x 曾售卖过旧 lifetime 产品，老用户恢复购买时任一命中即视为 Premium。
    /// 若确认从未售卖过旧 ID，可只保留 lifetimeID（此处保留防御性兼容）。
    let legacyLifetimeIDs = ["com.a1111.FocusHabit.premium.lifetime"]

    private var allLifetimeIDs: [String] {
        [lifetimeID] + legacyLifetimeIDs
    }

    private nonisolated(unsafe) var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        // 冷启动即恢复已购权益，避免已购用户重启后显示未购买
        Task { await checkEntitlements() }
    }

    nonisolated deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: allLifetimeIDs)
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
               allLifetimeIDs.contains(transaction.productID),
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
