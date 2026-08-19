import Foundation
import SwiftData

/// 版本化 Schema：为 SwiftData 提供显式版本标识与迁移入口，
/// 避免未来模型字段演进导致老用户本地 store 启动失败。
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitCompletion.self, FocusSession.self]
    }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AppSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}