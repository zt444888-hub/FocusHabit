import Foundation
import ObjectiveC

private let swizzleOnce: Void = {
    let original = #selector(Bundle.localizedString(forKey:value:table:))
    let swizzled = #selector(Bundle.fh_localizedString(forKey:value:table:))
    guard let originalMethod = class_getInstanceMethod(Bundle.self, original),
          let swizzledMethod = class_getInstanceMethod(Bundle.self, swizzled) else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}()

func setupLanguage() {
    _ = swizzleOnce
    if let lang = UserDefaults.standard.string(forKey: "appLanguage"), !lang.isEmpty {
        UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

extension Bundle {
        @objc func fh_localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard self == Bundle.main else {
            return (self as Bundle).fh_localizedString(forKey: key, value: value, table: tableName)
        }
        let lang: String
        if let stored = UserDefaults.standard.string(forKey: "appLanguage"), !stored.isEmpty {
            lang = stored
        } else {
            lang = deviceLanguageCode()
        }
        if let langDict = translations[key], let translated = langDict[lang] {
            return translated
        }
        return (self as Bundle).fh_localizedString(forKey: key, value: value, table: tableName)
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
