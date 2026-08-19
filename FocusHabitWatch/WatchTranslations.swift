import Foundation

/// Watch 端轻量本地化：跟随设备语言
func WT(_ key: String) -> String {
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    let lang = code == "zh" ? (Locale.current.language.script?.identifier == "Hant" ? "zh-Hant" : "zh-Hans") : code
    return watchTranslations[key]?[lang] ?? key
}

private let watchTranslations: [String: [String: String]] = [
    "Habits": ["en": "Habits", "zh-Hans": "习惯", "ja": "習慣", "fr": "Habitudes", "es": "Hábitos", "de": "Gewohnheiten", "ko": "습관"],
    "Timer": ["en": "Timer", "zh-Hans": "计时", "ja": "タイマー", "fr": "Minuteur", "es": "Temporizador", "de": "Timer", "ko": "타이머"],
    "Today": ["en": "Today", "zh-Hans": "今天", "ja": "今日", "fr": "Aujourd'hui", "es": "Hoy", "de": "Heute", "ko": "오늘"],
    "No Habits": ["en": "No Habits", "zh-Hans": "还没有习惯", "ja": "習慣がありません", "fr": "Aucune habitude", "es": "Sin hábitos", "de": "Keine Gewohnheiten", "ko": "습관이 없습니다"],
    "Open the iPhone app to add habits.": ["en": "Open the iPhone app to add habits.", "zh-Hans": "打开 iPhone 应用添加习惯。", "ja": "iPhoneアプリで習慣を追加してください。", "fr": "Ouvrez l'app iPhone pour ajouter des habitudes.", "es": "Abre la app del iPhone para añadir hábitos.", "de": "Öffne die iPhone-App, um Gewohnheiten hinzuzufügen.", "ko": "iPhone 앱에서 습관을 추가하세요."],
    "Start": ["en": "Start", "zh-Hans": "开始", "ja": "開始", "fr": "Démarrer", "es": "Iniciar", "de": "Starten", "ko": "시작"],
    "Pause": ["en": "Pause", "zh-Hans": "暂停", "ja": "一時停止", "fr": "Pause", "es": "Pausa", "de": "Pause", "ko": "일시정지"],
    "Reset": ["en": "Reset", "zh-Hans": "重置", "ja": "リセット", "fr": "Réinitialiser", "es": "Reiniciar", "de": "Zurücksetzen", "ko": "초기화"],
    "Pomodoro": ["en": "Pomodoro", "zh-Hans": "番茄", "ja": "ポモドーロ", "fr": "Pomodoro", "es": "Pomodoro", "de": "Pomodoro", "ko": "뽀모도로"],
    "Quick": ["en": "Quick", "zh-Hans": "快速", "ja": "クイック", "fr": "Rapide", "es": "Rápido", "de": "Kurz", "ko": "퀵"],
    "Deep": ["en": "Deep", "zh-Hans": "深度", "ja": "ディープ", "fr": "Profond", "es": "Profundo", "de": "Tief", "ko": "딥"],
]