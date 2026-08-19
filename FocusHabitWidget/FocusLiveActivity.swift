import ActivityKit
import SwiftUI
import WidgetKit

/// 番茄钟 Live Activity：灵动岛（compact / minimal / expanded）+ 锁屏横幅。
/// 运行态用 Text(timerInterval:) 由系统走秒（不逐秒 update，省电）；
/// 暂停态显示静态剩余时间。iOS 17 目标，ActivityKit 要求 iOS 16.1+。
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // 锁屏 / 横幅
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded（长按展开）— 保持单行紧凑胶囊，不放 bottom
                // 完整信息（presetName + 状态）放在锁屏横幅
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.body)
                        .foregroundStyle(.brand)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownText(context: context)
                        .font(.caption.monospacedDigit().weight(.semibold))
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.brand)
            } compactTrailing: {
                countdownText(context: context)
                    .font(.caption.monospacedDigit().weight(.semibold))
            } minimal: {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.brand)
            }
        }
    }

    /// 运行态：系统走秒；暂停态：静态剩余时间
    @ViewBuilder
    private func countdownText(context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        if context.state.isPaused {
            Text(formatTime(context.state.remainingSeconds))
        } else {
            let end = context.state.endDate
            Text(timerInterval: end.addingTimeInterval(-context.state.remainingSeconds)...end, countsDown: true)
        }
    }

    @ViewBuilder
    private func statusLabel(context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        if context.state.isPaused {
            Text(WT("Paused"))
        } else if context.state.isBreak {
            Text(WT("Break"))
        } else {
            Text(WT("Focusing"))
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// 锁屏横幅视图
private struct LockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.presetName)
                    .font(.headline)
                    .lineLimit(1)
                if context.state.isPaused {
                    Text(WT("Paused") + " · " + formatTime(context.state.remainingSeconds))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let end = context.state.endDate
                    Text(timerInterval: end.addingTimeInterval(-context.state.remainingSeconds)...end, countsDown: true)
                        .font(.title3.monospacedDigit().weight(.semibold))
                }
            }
            Spacer()
        }
        .padding(16)
        .activityBackgroundTint(.brand.opacity(0.15))
        .activitySystemActionForegroundColor(.brand)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
