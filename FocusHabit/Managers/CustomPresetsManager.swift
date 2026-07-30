import Foundation

struct CustomPresetsManager {
    private static nonisolated(unsafe) let defaults = UserDefaults(suiteName: "group.com.a1111.FocusHabit") ?? .standard
    private static let key = "CustomTimerPresets"

    static func load() -> [TimerPreset] {
        guard let data = defaults.data(forKey: key),
              let presets = try? JSONDecoder().decode([TimerPreset].self, from: data) else {
            return []
        }
        return presets
    }

    static func save(_ presets: [TimerPreset]) {
        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: key)
        }
    }

    static func add(_ preset: TimerPreset) {
        var presets = load()
        presets.append(preset)
        save(presets)
    }

    static func delete(at index: Int) {
        var presets = load()
        guard index < presets.count else { return }
        presets.remove(at: index)
        save(presets)
    }

    static func update(at index: Int, with preset: TimerPreset) {
        var presets = load()
        guard index < presets.count else { return }
        presets[index] = preset
        save(presets)
    }
}
