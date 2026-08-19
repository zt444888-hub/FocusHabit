import UIKit
import Social

/// 分享扩展：把分享内容当作「待创建/待打卡的习惯」写入 App Group，
/// 主 App 前台时经 ShareImport 消费并导入。
final class ShareViewController: SLComposeServiceViewController {
    private static let defaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit")
    private static let key = "pendingSharedHabitName"

    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder = NSLocalizedString("Habit name", comment: "")
        // 异步加载分享文本，避免在主线程同步等待 NSItemProvider（信号量阻塞会死锁/被杀）
        Task { @MainActor in
            if let hint = await extractSharedText(), !hint.isEmpty {
                textView.text = hint
            }
        }
    }

    override func isContentValid() -> Bool {
        !contentText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    override func didSelectPost() {
        let name = contentText.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            Self.defaults?.set(name, forKey: Self.key)
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    override func configurationItems() -> [Any]! {
        [] // 仅提供文本框，无需额外配置项
    }

    /// 尽量从分享的链接/文本中提取可用的名称（异步，iOS 15+ NSItemProvider async API）
    private func extractSharedText() async -> String? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return nil }
        for item in items {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                guard provider.hasItemConformingToTypeIdentifier("public.plain-text") else { continue }
                do {
                    if let loaded = try await provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil),
                       let s = loaded as? String {
                        let first = s.components(separatedBy: "\n").first
                        if let r = first, !r.isEmpty { return r }
                    }
                } catch {
                    continue
                }
            }
        }
        return nil
    }
}
