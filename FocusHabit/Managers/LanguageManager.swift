import Foundation

/// 应用内语言切换：把选择写入 UserDefaults（appLanguage 供 T() 查询、AppleLanguages 供系统组件），
/// 系统组件（DatePicker 等）在下次启动后跟随。不再使用 Bundle swizzling ——
/// 全局 method_exchangeImplementations 属于系统级侵入，无必要风险，已移除。
func setupLanguage() {
    if let lang = UserDefaults.standard.string(forKey: "appLanguage"), !lang.isEmpty {
        UserDefaults.standard.set([lang], forKey: "AppleLanguages")
    }
}

func deviceLanguageCode() -> String {
    let locale = Locale.current
    let code = locale.language.languageCode?.identifier ?? "en"
    if code == "zh" {
        let script = locale.language.script?.identifier
        return script == "Hant" ? "zh-Hant" : "zh-Hans"
    }
    let supported = ["en", "zh-Hans", "ja", "fr", "es", "de", "ko"]
    return supported.contains(code) ? code : "en"
}

func T(_ key: String) -> String {
    let lang: String
    if let stored = UserDefaults.standard.string(forKey: "appLanguage"), !stored.isEmpty {
        lang = stored
    } else {
        lang = deviceLanguageCode()
    }
    return translations[key]?[lang] ?? key
}
