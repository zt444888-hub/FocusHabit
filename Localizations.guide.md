# 多语言本地化指南 — FocusHabit

## 在 Xcode 中设置（2 分钟）

1. 在 Xcode 中打开项目 → 选中 **Project navigator** 最顶层的项目文件
2. 选择 **Info** 标签页 → 找到 **Localizations** 区域
3. 点击 **+** → 勾选 **Japanese (ja)** → 选择所有文件 → Finish
4. 重复第 3 步添加 **Spanish (es)** 和 **German (de)**
5. Xcode 会在项目里生成 `Localizable.xcstrings` 文件
6. **打开 `Localizable.xcstrings`** — 你会看到所有字符串的表格
7. 在每行的 ja / es / de 列粘贴下面的翻译即可

> 提示：`Localizable.xcstrings` 是 Xcode 15+ 自动管理的格式。你不需要写代码。
> 所有在 `Text("...")`、`Label("...")`、`Button("...")` 里出现的字符串都会被自动提取。

---

## 完整翻译对照表

### Tab / 导航

| English | 日本語 (ja) | Español (es) | Deutsch (de) |
|---------|------------|-------------|-------------|
| Habits | 習慣 | Hábitos | Gewohnheiten |
| Focus | 集中 | Enfoque | Fokus |
| Settings | 設定 | Ajustes | Einstellungen |

### 习惯列表

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| Add Habit | 習慣を追加 | Añadir hábito | Gewohnheit hinzufügen |
| Delete | 削除 | Eliminar | Löschen |
| streak | 連続日数 | racha | Serie |
| Build your habits | 習慣を作ろう | Construye tus hábitos | Baue deine Gewohnheiten auf |
| Start small. Stay consistent.\nAdd your first habit to begin. | 小さく始めて、継続しよう。\n最初の習慣を追加しましょう。 | Empieza poco a poco. Sé constante.\nAñade tu primer hábito. | Fang klein an. Bleib beständig.\nFüge deine erste Gewohnheit hinzu. |

### 添加/编辑习惯

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| New Habit | 新しい習慣 | Nuevo hábito | Neue Gewohnheit |
| Edit Habit | 習慣を編集 | Editar hábito | Gewohnheit bearbeiten |
| What do you want to track? | 何を記録しますか？ | ¿Qué quieres registrar? | Was möchtest du verfolgen? |
| Habit name | 習慣名 | Nombre del hábito | Name der Gewohnheit |
| Frequency | 頻度 | Frecuencia | Häufigkeit |
| Daily | 毎日 | Diario | Täglich |
| Weekly | 毎週 | Semanal | Wöchentlich |
| Weekdays | 平日 | Entre semana | Werktags |
| Weekends | 週末 | Fin de semana | Wochenende |
| Daily Reminder | 毎日のリマインダー | Recordatorio diario | Tägliche Erinnerung |
| Time | 時間 | Hora | Uhrzeit |
| Reminder | リマインダー | Recordatorio | Erinnerung |
| Cancel | キャンセル | Cancelar | Abbrechen |
| Save | 保存 | Guardar | Speichern |

### 专注计时

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| Focus | 集中 | Enfoque | Fokus |
| Session Complete! | セッション完了！ | ¡Sesión completada! | Sitzung abgeschlossen! |
| Great focus! Did you work on a habit? | よく集中できました！習慣に取り組みましたか？ | ¡Buen enfoque! ¿Trabajaste en un hábito? | Gut fokussiert! Hast du an einer Gewohnheit gearbeitet? |
| Skip | スキップ | Saltar | Überspringen |
| Ready | 準備完了 | Listo | Bereit |
| Paused | 一時停止 | Pausado | Pausiert |
| Focusing... | 集中中... | Enfocándose... | Fokussieren... |
| Pomodoro | ポモドーロ | Pomodoro | Pomodoro |
| Quick | クイック | Rápido | Kurz |
| Deep Work | ディープワーク | Trabajo profundo | Tiefenarbeit |
| Pomodoros | ポモドーロ数 | Pomodoros | Pomodoros |
| Habits Done | 完了した習慣 | Hábitos completados | Erledigte Gewohnheiten |

### 周视图

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| This Week | 今週 | Esta semana | Diese Woche |
| %lld habits | %lld 個の習慣 | %lld hábitos | %lld Gewohnheiten |

> 注意：带数字的字符串在 .xcstrings 中用 `%lld` 代表整数占位符

### 设置

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| FocusHabit | FocusHabit | FocusHabit | FocusHabit |
| Build habits that stick. | 続く習慣を作ろう。 | Construye hábitos que perduren. | Baue Gewohnheiten, die bleiben. |
| Your Stats | 統計 | Tus estadísticas | Deine Statistiken |
| Total Habits | 全習慣数 | Hábitos totales | Gewohnheiten gesamt |
| Active Habits | アクティブな習慣 | Hábitos activos | Aktive Gewohnheiten |
| Total Completions | 完了総数 | Completados totales | Abschlüsse gesamt |
| Data | データ | Datos | Daten |
| Delete All Data | すべてのデータを削除 | Eliminar todos los datos | Alle Daten löschen |
| About | このアプリについて | Acerca de | Über |
| Version | バージョン | Versión | Version |
| Rate on App Store | App Store で評価 | Calificar en App Store | Im App Store bewerten |
| Reset All Data? | すべてのデータをリセット？ | ¿Restablecer todos los datos? | Alle Daten zurücksetzen? |
| This will permanently delete all your habits and history. | すべての習慣と履歴が完全に削除されます。 | Esto eliminará permanentemente todos tus hábitos e historial. | Dadurch werden alle deine Gewohnheiten und Verläufe endgültig gelöscht. |

### 通知

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| Don't forget your habit today! | 今日の習慣をお忘れなく！ | ¡No olvides tu hábito de hoy! | Vergiss deine Gewohnheit heute nicht! |

### Widget

| English | 日本語 | Español | Deutsch |
|---------|--------|---------|---------|
| Today's Habits | 今日の習慣 | Hábitos de hoy | Heutige Gewohnheiten |
| No habits yet | まだ習慣がありません | Aún no hay hábitos | Noch keine Gewohnheiten |
| See and track your daily habits. | 毎日の習慣を確認・記録。 | Ve y registra tus hábitos diarios. | Sieh und verfolge deine täglichen Gewohnheiten. |

---

## App Store 元数据翻译

上架时，App Store Connect 的「App Information」和「Product Page」需要为每种语言填独立的内容：

### 副标题 (Subtitle)

| Language | Text |
|----------|------|
| English | Habit tracker & focus timer |
| 日本語 | 習慣トラッカー＆集中タイマー |
| Español | Rastreador de hábitos y temporizador de enfoque |
| Deutsch | Gewohnheits-Tracker & Fokus-Timer |

### 关键词 (Keywords)

| Language | Keywords |
|----------|----------|
| English | habit tracker, focus timer, pomodoro, daily routine, streak, productivity, mindfulness, task manager |
| 日本語 | 習慣, 習慣トラッカー, 集中, タイマー, ポモドーロ, ルーティン, 生産性 |
| Español | hábitos, rutina, productividad, temporizador, enfoque, pomodoro, mindfulness |
| Deutsch | Gewohnheiten, Routine, Produktivität, Timer, Fokus, Pomodoro, Achtsamkeit |

### 描述 (Description) — 第一段

**English**
> FocusHabit helps you build lasting habits with a simple, beautiful interface. Track your daily routines, maintain your streak, and stay focused with the built-in Pomodoro timer — all in one app. No subscription. No ads. One purchase, forever.

**日本語**
> FocusHabit はシンプルで美しいインターフェースで、続く習慣づくりをサポートします。毎日のルーティンを記録し、連続日数を維持し、内蔵のポモドーロタイマーで集中力を高めましょう。すべて1つのアプリで。サブスクリプションなし、広告なし。一度の購入でずっと使えます。

**Español**
> FocusHabit te ayuda a construir hábitos duraderos con una interfaz simple y hermosa. Registra tus rutinas diarias, mantén tu racha y mantente enfocado con el temporizador Pomodoro integrado, todo en una sola app. Sin suscripción. Sin anuncios. Una compra, para siempre.

**Deutsch**
> FocusHabit hilft dir, beständige Gewohnheiten mit einer einfachen, schönen Oberfläche aufzubauen. Verfolge deine täglichen Routinen, behalte deine Serie bei und bleibe mit dem integrierten Pomodoro-Timer fokussiert – alles in einer App. Kein Abo. Keine Werbung. Ein Kauf, für immer.

---

## 截图本地化的快速做法

如果你没有预算请翻译：

1. **主要用英文截图** — 全球通用性最强
2. 用 **iPhone 模拟器** 运行 App，系统语言设为目标语言后截图
3. Xcode → Scheme → Edit Scheme → Run → **Arguments Passed On Launch** 加：
   `-AppleLanguages (ja)` — 启动日文界面
   `-AppleLanguages (es)` — 西班牙语
   `-AppleLanguages (de)` — 德语
4. 模拟器会显示对应语言的 UI，截图即可
5. 这些截图上传到 App Store Connect 对应语言的版本下

