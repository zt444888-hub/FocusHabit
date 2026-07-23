import Foundation

/// App Store 相关配置 — 上架前替换成实际值
enum AppStoreConfig {
    /// 在 App Store Connect 创建 App 后获得的 Apple ID
    static let appleID = "6785076515"
    
    /// App Store 评分链接（自动生成）
    static var reviewURL: URL {
        URL(string: "https://apps.apple.com/app/\(appleID)?action=write-review")!
    }
}
