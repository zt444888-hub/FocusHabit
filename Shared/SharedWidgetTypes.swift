import Foundation

/// 共享给主 App Target 和 Widget Extension 的 Widget 数据类型
struct WidgetHabit: Codable, Identifiable {
    let id: String
    let name: String
    let isCompleted: Bool
    let streak: Int
    let weeklyRate: Double
}
