import Foundation
import SwiftData

/// 习惯删除的统一门面。
/// 先解除与 FocusSession 的 relatedHabit 关系再删除，规避 SwiftData 关系处理在删除时卡死；
/// 所有删除路径（列表 / 归档页 / 重置全部数据）必须走这里，保证语义一致。
@MainActor
enum HabitStore {
    static func delete(_ habit: Habit, context: ModelContext) {
        NotificationManager.removeHabitReminder(for: habit)
        // 定向清空该习惯关联的专注记录，避免全量 fetch 与悬空引用
        let related = (try? context.fetch(FetchDescriptor<FocusSession>()))?.filter {
            $0.relatedHabit?.id == habit.id
        } ?? []
        for session in related {
            session.relatedHabit = nil
        }
        context.delete(habit)
        try? context.save()
    }
}
