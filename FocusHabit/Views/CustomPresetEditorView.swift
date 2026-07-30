import SwiftUI

struct CustomPresetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var focusMinutes: Int
    @State private var breakMinutes: Int

    private let onSave: (TimerPreset) -> Void
    private let onDelete: (() -> Void)?
    private let isEditing: Bool

    init(preset: TimerPreset? = nil, onSave: @escaping (TimerPreset) -> Void, onDelete: (() -> Void)? = nil) {
        self.onSave = onSave
        self.onDelete = onDelete
        self.isEditing = preset != nil
        _name = State(initialValue: preset?.name ?? "")
        _focusMinutes = State(initialValue: preset.flatMap { Int($0.focusDuration / 60) } ?? 25)
        _breakMinutes = State(initialValue: preset.flatMap { Int($0.breakDuration / 60) } ?? 5)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(T("Preset name"), text: $name)
                }

                Section {
                    Stepper("Focus: \(focusMinutes) min", value: $focusMinutes, in: 1...180)
                    Stepper("Break: \(breakMinutes) min", value: $breakMinutes, in: 1...60)
                } header: {
                    Text(verbatim: T("Duration"))
                }

                if let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label(T("Delete Preset"), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Preset" : "New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(T("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(T("Save")) {
                        let preset = TimerPreset(
                            focusDuration: TimeInterval(focusMinutes * 60),
                            breakDuration: TimeInterval(breakMinutes * 60),
                            name: name.trimmingCharacters(in: .whitespaces)
                        )
                        onSave(preset)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
