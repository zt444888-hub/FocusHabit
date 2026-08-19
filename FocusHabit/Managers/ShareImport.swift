import Foundation

/// 负责读取并清理「分享扩展」写入的待导入习惯名。
/// 分享扩展把内容写入 App Group 共享 UserDefaults，主 App 在前台时消费并创建习惯。
enum ShareImport {
    private static let defaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit")
    private static let key = "pendingSharedHabitName"

    /// 取走一条待导入的习惯名；无则返回 nil。
    static func consumePending() -> String? {
        guard let name = defaults?.string(forKey: key), !name.isEmpty else { return nil }
        defaults?.removeObject(forKey: key)
        return name
    }
}