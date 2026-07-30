 import SwiftUI
 import SwiftData
 
 struct AddHabitView: View {
     let habit: Habit?
     @Environment(\.modelContext) private var context
     @Environment(\.dismiss) private var dismiss
     
     @State private var name = ""
     @State private var frequency: Frequency = .daily
     @State private var hasReminder = false
    @State private var targetDaysPerWeek = 7
    @State private var selectedColor = "brand"
    @State private var selectedIcon = "checklist"
    @State private var canRepeatDaily = false
     @State private var reminderTime = Date()
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var activeHabits: [Habit]
    @State private var showPaywall = false
     
     private var isEditing: Bool { habit != nil }
     
     init(habit: Habit? = nil) {
         self.habit = habit
         if let h = habit {
             _name = State(initialValue: h.name)
             _frequency = State(initialValue: h.frequency)
             _selectedColor = State(initialValue: h.colorName)
             _selectedIcon = State(initialValue: h.iconName)
             _targetDaysPerWeek = State(initialValue: h.targetDaysPerWeek)
             _canRepeatDaily = State(initialValue: h.canRepeatDaily)
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
                     TextField(T("Habit name"), text: $name)
                         .font(.body)
                 } header: {
                     Text(verbatim: T("What do you want to track?"))
                         .font(.subheadline)
                 }
                 
                 Section {
                     Picker(T("Frequency"), selection: $frequency) {
                         ForEach(Frequency.allCases, id: \.self) { freq in
                             Label(T(freq.rawValue), systemImage: freq.systemImage)
                                 .tag(freq)
                         }
                     }
                     .pickerStyle(.menu)
                 }

                 Section(T("Icon")) {
                     LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                         ForEach(["checklist", "book", "figure.run", "flame", "drop", "heart", "star", "moon", "sun.max", "leaf", "brain", "bicycle"], id: \.self) { icon in
                             Button {
                                 selectedIcon = icon
                             } label: {
                                 Image(systemName: icon)
                                     .font(.title3)
                                     .foregroundColor(selectedIcon == icon ? .white : Color(selectedColor))
                                     .frame(width: 40, height: 40)
                                     .background(selectedIcon == icon ? Color(selectedColor) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                             }
                         }
                     }
                     .buttonStyle(.borderless)
                 }

                 Section(T("Color")) {
                     LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                         ForEach(["brand", "orange", "red", "pink", "purple", "blue", "green", "teal", "yellow", "brown", "mint", "indigo"], id: \.self) { color in
                             Button {
                                 selectedColor = color
                             } label: {
                                 Circle()
                                     .fill(Color(color))
                                     .frame(width: 36, height: 36)
                                     .overlay(
                                         selectedColor == color ?
                                         Image(systemName: "checkmark")
                                             .font(.caption.weight(.bold))
                                             .foregroundColor(.white) : nil
                                     )
                             }
                         }
                     }
                     .buttonStyle(.borderless)
                 }

                 Section(T("Weekly Goal")) {
                     Stepper("\(targetDaysPerWeek) days / week", value: $targetDaysPerWeek, in: 1...7)
                 }

                 Section {
                     Toggle(T("Allow multiple daily completions"), isOn: $canRepeatDaily)
                 } header: {
                     Text(verbatim: T("Repeat"))
                 }
                 
                 Section {
                     Toggle(T("Daily Reminder"), isOn: $hasReminder.animation())
                     if hasReminder {
                         DatePicker(T("Time"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                     }
                 } header: {
                     Text(verbatim: T("Reminder"))
                 }
             }
             .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
             .navigationBarTitleDisplayMode(.inline)
             .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button(T("Cancel")) { dismiss() }
                 }
                 ToolbarItem(placement: .confirmationAction) {
                     Button(T("Save")) { save() }
                         .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                 }
             }
             .sheet(isPresented: $showPaywall) {
                 PaywallView()
             }
         }
     }
     
     private func save() {
         let trimmed = name.trimmingCharacters(in: .whitespaces)
         guard !trimmed.isEmpty else { return }
         
         if let existing = habit {
             existing.name = trimmed
             existing.frequency = frequency
             existing.colorName = selectedColor
             existing.iconName = selectedIcon
             existing.canRepeatDaily = canRepeatDaily
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
             if !StoreManager.shared.isPremium && activeHabits.count >= StoreManager.shared.maxFreeHabits {
                 showPaywall = true
                 return
             }
             let newHabit = Habit(name: trimmed, frequency: frequency,
                                  reminderTime: hasReminder ? reminderTime : nil,
                                  sortOrder: 0, targetDaysPerWeek: targetDaysPerWeek, colorName: selectedColor, iconName: selectedIcon, canRepeatDaily: canRepeatDaily)
             context.insert(newHabit)
            try? context.save()
             if hasReminder {
                 NotificationManager.scheduleHabitReminder(for: newHabit)
             }
         }
         dismiss()
     }
 }

