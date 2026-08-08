import Foundation

/// 小组件本地化：跟随设备语言（独立于主 App 的自定义翻译系统）
func WT(_ key: String) -> String {
    let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
    let lang: String
    if languageCode == "zh" {
        lang = Locale.current.language.script?.identifier == "Hant" ? "zh-Hant" : "zh-Hans"
    } else {
        lang = languageCode
    }
    return translations[key]?[lang] ?? key
}

private let translations: [String: [String: String]] = [
    "Today's Habits": [
        "en": "Today's Habits",
        "zh-Hans": "今日习惯",
        "zh-Hant": "今日習慣",
        "ja": "今日の習慣",
        "fr": "Habitudes du jour",
        "es": "Hábitos de hoy",
        "de": "Heutige Gewohnheiten",
        "ko": "오늘의 습관"
    ],
    "No habits yet": [
        "en": "No habits yet",
        "zh-Hans": "还没有习惯",
        "zh-Hant": "還沒有習慣",
        "ja": "まだ習慣がありません",
        "fr": "Pas encore d'habitudes",
        "es": "Aún no hay hábitos",
        "de": "Noch keine Gewohnheiten",
        "ko": "아직 습관이 없습니다"
    ],
    "Today's Habits (Widget)": [
        "en": "Today's Habits",
        "zh-Hans": "今日习惯",
        "zh-Hant": "今日習慣",
        "ja": "今日の習慣",
        "fr": "Habitudes du jour",
        "es": "Hábitos de hoy",
        "de": "Heutige Gewohnheiten",
        "ko": "오늘의 습관"
    ],
    "See and track your daily habits.": [
        "en": "See and track your daily habits.",
        "zh-Hans": "查看并追踪你的每日习惯。",
        "zh-Hant": "查看並追蹤你的每日習慣。",
        "ja": "毎日の習慣を確認・記録します。",
        "fr": "Consultez et suivez vos habitudes quotidiennes.",
        "es": "Consulta y sigue tus hábitos diarios.",
        "de": "Sieh und verfolge deine täglichen Gewohnheiten.",
        "ko": "매일의 습관을 확인하고 기록하세요."
    ]
]
