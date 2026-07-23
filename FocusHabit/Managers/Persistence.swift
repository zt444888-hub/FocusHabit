import Foundation
import SwiftData
import OSLog

private let log = Logger(subsystem: "com.yourapp.FocusHabit", category: "persistence")

extension ModelContext {
    /// 安全保存并记录错误（不会弹 UI 打断用户）
    func saveAndLog() {
        do {
            try save()
        } catch {
            log.error("ModelContext save failed: \(error.localizedDescription)")
        }
    }
}
