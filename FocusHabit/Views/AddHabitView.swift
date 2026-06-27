 import SwiftUI
 import SwiftData
 
 struct AddHabitView: View {
     @Bindable var habit: Habit?
     @Environment(\.modelContext) private var context
     @Environment(\.dismiss) private var dismiss
     
     @State private var name = ""
     @State private var frequency: Frequency = .daily
     @State private var hasReminder = false
     @State private var reminderTime = Date()
     
     private var isEditing: Bool { habit != nil }
     
     init(habit: Habit? = nil) {
         self.habit = habit
         if let h = habit {
             _name = State(initialValue: h.name)
             _frequency = State(initialValue: h.frequency)
             if h.reminderTime != nil {
                 _hasReminder = State(initialValue: true)
                 _reminderTime = State(initialValue: h.reminderTime!)
             }
         }
     }
     
     var body: some View {
         NavigationStack {
             Form {
                 Section {
                     TextField("Habit name", text: $name)
                         .font(.body)
                 } header: {
                     Text("What do you want to track?")
                         .font(.subheadline)
                 }
                 
                 Section {
                     Picker("Frequency", selection: $frequency) {
                         ForEach(Frequency.allCases, id: \.self) { freq in
                             Label(freq.rawValue, systemImage: freq.systemImage)
                                 .tag(freq)
                         }
                     }
                     .pickerStyle(.menu)
                 }
                 
                 Section {
                     Toggle("Daily Reminder", isOn: $hasReminder.animation())
                     if hasReminder {
                         DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                     }
                 } header: {
                     Text("Reminder")
                 }
             }
             .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
             .navigationBarTitleDisplayMode(.inline)
             .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button("Cancel") { dismiss() }
                 }
                 ToolbarItem(placement: .confirmationAction) {
                     Button("Save") { save() }
                         .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                 }
             }
         }
     }
     
     private func save() {
         let trimmed = name.trimmingCharacters(in: .whitespaces)
         guard !trimmed.isEmpty else { return }
         
         if let existing = habit {
             existing.name = trimmed
             existing.frequency = frequency
             if hasReminder {
                 existing.reminderTime = reminderTime
                 NotificationManager.scheduleHabitReminder(for: existing)
             } else {
                 if existing.reminderTime != nil {
                     NotificationManager.removeHabitReminder(for: existing)
                 }
                 existing.reminderTime = nil
             }
         } else {
             let newHabit = Habit(name: trimmed, frequency: frequency,
                                  reminderTime: hasReminder ? reminderTime : nil,
                                  sortOrder: 0)
             context.insert(newHabit)
            try? context.save()
             if hasReminder {
                 NotificationManager.scheduleHabitReminder(for: newHabit)
             }
         }
         dismiss()
     }
 }

