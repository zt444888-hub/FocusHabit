import SwiftUI

struct PresetListView: View {
    @State private var customPresets: [TimerPreset] = CustomPresetsManager.load()
    @State private var showEditor = false
    @State private var editingPreset: TimerPreset?
    @State private var editingIndex: Int?
    @State private var showPaywall = false

    private let builtIns: [TimerPreset] = [.pomodoro, .short, .deep]

    var body: some View {
        List {
            Section(T("Built-in")) {
                ForEach(builtIns) { preset in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name)
                            .font(.headline)
                        Text("\(Int(preset.focusDuration / 60))min focus / \(Int(preset.breakDuration / 60))min break")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(T("Custom")) {
                if !StoreManager.shared.isPremium {
                    HStack {
                        Label(T("Unlock Custom Presets"), systemImage: "crown.fill")
                            .foregroundColor(.brand)
                        Spacer()
                        Button(T("Upgrade")) { showPaywall = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.brand)
                    }
                } else if customPresets.isEmpty {
                    Text(verbatim: T("No custom presets"))
                        .foregroundColor(.secondary)
                }
                ForEach(Array(customPresets.enumerated()), id: \.element.id) { i, preset in
                    Button {
                        editingPreset = preset
                        editingIndex = i
                        showEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(Int(preset.focusDuration / 60))min focus / \(Int(preset.breakDuration / 60))min break")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        CustomPresetsManager.delete(at: i)
                    }
                    customPresets = CustomPresetsManager.load()
                        NotificationCenter.default.post(name: .init("CustomPresetsChanged"), object: nil)
                }
            }
        }
        .navigationTitle(T("Timer Presets"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if StoreManager.shared.isPremium {
                        editingPreset = nil
                        editingIndex = nil
                        showEditor = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showEditor) {
            CustomPresetEditorView(
                preset: editingPreset,
                onSave: { preset in
                    if let idx = editingIndex {
                        CustomPresetsManager.update(at: idx, with: preset)
                    } else {
                        CustomPresetsManager.add(preset)
                    }
                    customPresets = CustomPresetsManager.load()
                        NotificationCenter.default.post(name: .init("CustomPresetsChanged"), object: nil)
                },
                onDelete: editingIndex != nil ? {
                    if let idx = editingIndex {
                        CustomPresetsManager.delete(at: idx)
                        customPresets = CustomPresetsManager.load()
                        NotificationCenter.default.post(name: .init("CustomPresetsChanged"), object: nil)
                    }
                } : nil
            )
        }
    }
}
