import ActivityKit
import Foundation

/// 番茄钟 Live Activity 的 ActivityAttributes。
/// 主 App（TimerManager）负责 request/update/end，Widget Extension 负责渲染。
/// 零后端：不使用 pushType，倒计时由系统按 endDate 走秒，App 被杀后仍能走完。
struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 暂停态：UI 显示静态剩余时间（remainingSeconds）而非 timerInterval 走秒
        var isPaused: Bool
        /// 是否为休息轮（当前产品未自动运行 break，字段保留供后续扩展）
        var isBreak: Bool
        /// 本轮结束时刻（运行态由系统据此走秒）
        var endDate: Date
        /// 剩余秒数（暂停态显示用）
        var remainingSeconds: TimeInterval
    }

    /// 预设名（Pomodoro / Quick / Deep Work / 自定义 / 习惯名）
    var presetName: String
}
