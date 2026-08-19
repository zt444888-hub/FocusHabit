import ActivityKit
import Foundation
import UIKit

/// 番茄钟 Live Activity 的统一门面。
/// TimerManager 在 start/pause/reset/skip/complete 时调用 sync / endCurrent。
/// 设计原则：
/// - 不使用 pushType（零云端），endDate 由系统驱动走秒，App 被杀后 Activity 依然正确走完；
/// - 运行态不逐秒 update（省电），只有状态切换（暂停/恢复）才 update；
/// - Activity.request 失败（用户关闭 Live Activities / 机型不支持）时静默降级，不影响计时器主逻辑。
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<FocusActivityAttributes>?

    private init() {}

    /// 同步当前计时状态到 Live Activity。
    /// - Parameters:
    ///   - isRunning: 是否运行中
    ///   - isPaused: 是否暂停
    ///   - endDate: 本轮结束时刻（运行态）
    ///   - remaining: 剩余秒数（暂停态显示）
    ///   - isBreak: 是否休息轮
    ///   - presetName: 预设名
    func sync(
        isRunning: Bool,
        isPaused: Bool,
        endDate: Date,
        remaining: TimeInterval,
        isBreak: Bool,
        presetName: String
    ) {
        let state = FocusActivityAttributes.ContentState(
            isPaused: isPaused,
            isBreak: isBreak,
            endDate: endDate,
            remainingSeconds: remaining
        )

        if let activity = currentActivity {
            NSLog("[FocusHabit LiveActivity] update: paused=\(isPaused) endDate=\(endDate)")
            Task { await activity.update(using: state) }
        } else if isRunning {
            // 清理系统残留的历史 Activity（如上次崩溃未 end），再申请新的
            for stale in Activity<FocusActivityAttributes>.activities {
                Task { await stale.end(using: stale.contentState, dismissalPolicy: .immediate) }
            }
            let attributes = FocusActivityAttributes(presetName: presetName)
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
                NSLog("[FocusHabit LiveActivity] request OK id=\(currentActivity!.id) ios=\(UIDevice.current.systemVersion) model=\(UIDevice.current.model)")
            } catch {
                // 打印失败原因：Live Activities 被关闭 / 模拟器限制 / 机型不支持等
                NSLog("[FocusHabit LiveActivity] request FAILED: \(error.localizedDescription) | ios=\(UIDevice.current.systemVersion) model=\(UIDevice.current.model)")
            }
        }
    }

    /// 结束当前 Live Activity（reset / skip break / 一轮完成时调用）
    func endCurrent() {
        guard let activity = currentActivity else { return }
        Task { await activity.end(using: activity.contentState, dismissalPolicy: .immediate) }
        currentActivity = nil
    }
}
