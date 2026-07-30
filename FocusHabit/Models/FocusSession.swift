import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: String = UUID().uuidString
    var date: Date
    var duration: TimeInterval       // 专注时长（秒）
    var presetName: String           // 使用的预设名
    var startTime: Date
    var endTime: Date
    var relatedHabit: Habit?         // 关联习惯，显式关系让 SwiftData 匹配逆关系

    init(
        startTime: Date,
        duration: TimeInterval,
        presetName: String
    ) {
        self.date = Calendar.current.startOfDay(for: startTime)
        self.startTime = startTime
        self.endTime = startTime.addingTimeInterval(duration)
        self.duration = duration
        self.presetName = presetName
    }
}
