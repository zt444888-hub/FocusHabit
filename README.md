 # FocusHabit — 专注习惯追踪 App
 
 > 极简设计，$2.99 买断，纯本地运行。Combine: habit tracking + Pomodoro focus timer.
 
 ## 项目结构
 
 ```
 FocusHabit/
 ├── FocusHabit/                      # App 主 Target
 │   ├── FocusHabitApp.swift          # App 入口 + SwiftData 配置
 │   ├── Models/
 │   │   └── HabitModel.swift         # Habit, HabitCompletion, TimerPreset 模型
 │   ├── Views/
 │   │   ├── ContentView.swift        # 主 TabView (Habits / Focus / Settings)
 │   │   ├── HabitListView.swift      # 习惯列表 + 每周日历头部
 │   │   ├── HabitCardView.swift      # 单个习惯卡片 (打勾/连续天数/周进度环)
 │   │   ├── AddHabitView.swift       # 添加/编辑习惯表单
 │   │   ├── FocusTimerView.swift     # 番茄钟专注计时器
 │   │   ├── WeekCalendarView.swift   # 周视图日历 (显示本周习惯完成情况)
 │   │   └── SettingsView.swift       # 设置页 (统计/重置数据)
 │   ├── Managers/
 │   │   ├── TimerManager.swift       # 番茄钟逻辑 @Observable
 │   │   ├── NotificationManager.swift# 本地通知
 │   │   └── WidgetDataWriter.swift   # App → Widget 数据同步
 │   └── Resources/                   # 空 (使用 SF Symbols)
 │
 └── FocusHabitWidget/               # Widget Extension
     └── FocusHabitWidget.swift       # iOS Widget (Small + Medium)
 ```
 
 ## 特色功能
 
 ### 习惯追踪
 - 添加/编辑/删除习惯（名称、频率、提醒时间）
 - 每日打卡（点击圆圈打勾，带弹簧动画 + haptic）
 - 连续天数（Streak）自动统计
 - 周视图日历（每个小圆点代表一个习惯的完成状态）
 - 周完成率进度环（环形图）
 
 ### 专注计时
 - 三个预设：Pomodoro (25min/5min)、Quick (10min/3min)、Deep Work (45min/10min)
 - 圆形倒计时动画（AngularGradient 橙色渐变）
 - 番茄钟完成 → 弹窗询问是否关联到某个习惯
 - 今天完成番茄钟次数统计
 
 ### 系统集成
 - iOS Widget（小/中两种尺寸，显示今日习惯和连续天数）
 - 本地通知提醒
 - 暗黑模式支持（SwiftUI 原生）
 
 ### 设计风格
 - 暖色配色（橙色 + 暖白 + 柔和阴影）
 - SF Rounded 字体
 - 圆角卡片（16pt），轻阴影，无冗余装饰
 - 弹簧动画（打勾 check、页面切换）
 
 ## 在 Xcode 中打开
 
 ### 方式 A：从零创建 Xcode 项目（推荐）
 
 1. 打开 Xcode → "Create New Project"
 2. 选择 **iOS → App**
 3. 项目名：`FocusHabit` | Interface: **SwiftUI** | Language: **Swift**
 4. 勾选 "Include Widget" → Widget Extension 名：`FocusHabitWidget`
 5. 选择保存位置，创建项目
 6. **将本 README 同目录下的所有 `.swift` 文件拖入 Xcode 项目导航器中**（对应目标勾选主 App Target）
     - `FocusHabit/` 下所有文件 → 主 App Target
     - `FocusHabitWidget/` 下所有文件 → Widget Extension Target
 7. 配置 App Groups（用于 Widget 数据共享）：
     - 主 Target → Signing & Capabilities → +Capability → App Groups
     - 添加 `group.com.yourapp.FocusHabit`（可在项目配置中改成你的 Bundle ID）
     - Widget Extension 目标也添加同一个 App Group
 8. 在 `WidgetDataWriter.swift` 和 `FocusHabitWidget.swift` 中，将 `group.com.yourapp.FocusHabit` 替换为你的实际 App Group ID
 9. 选择一个模拟器 → Cmd+R 运行
 
 ### 方式 B：使用 Swift Package（高级）
 
 如果你习惯用 SPM 构建 iOS 项目，也可以创建一个 Package.swift 指向 iOS 平台，然后通过 Xcode 打开。
 
 ## 发布前检查清单
 
 - [ ] 替换 Bundle Identifier 为你的实际 ID
 - [ ] 替换 App Group 名称
 - [ ] 配置开发者签名（Team 选择你的 Apple Developer account）
 - [ ] 配置 App Store Connect 中的 App 信息和定价（$2.99）
 - [ ] 准备英文 App Store 截图（用模拟器录制）
 - [ ] 填写副标题和关键词（ASO）
 - [ ] 设置隐私政策 URL（可用免费模板）
 
 ## 技术栈
 
 - Swift 6 + SwiftUI
 - SwiftData（数据持久化）
 - WidgetKit（小组件）
 - UserNotifications（本地提醒）
 - 无需外部依赖
 
 ## 设计理念
 
 > "Streaks 的极简 + Forest 的专注 — 一次付费，永久使用，无订阅，无广告。"
 
 核心定位：
 - 每人每天只需要管理 6-12 个习惯
 - 专注和习惯是同一件事的两个面
 - 好设计 + 好体验 = 用户愿意付费
 - 买断制 vs 订阅制是差异化武器
 
 ## 许可
 
 仅供个人开发使用。
