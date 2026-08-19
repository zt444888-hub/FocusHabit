import SwiftData

/// 主 App 与快捷指令/分享扩展共用的 ModelContainer 仓库。
/// App 启动时注册其创建的容器，AppIntent 可从同一容器读取同一数据，保证一致。
@MainActor
enum AppModelStore {
    static var container: ModelContainer?
    static var mainContext: ModelContext? { container?.mainContext }
}