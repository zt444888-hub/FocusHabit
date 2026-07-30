 import SwiftUI
 import SwiftData
 
 struct HabitCardView: View {
     @Bindable var habit: Habit
     @Environment(\.modelContext) private var context
     @State private var animateCheck = false
    var onShowDetail: ((Habit) -> Void)?
    @State private var showBackfill = false
    @State private var backfillDate = Date()
     
     var body: some View {
         HStack(spacing: 16) {
             checkButton
             infoSection
             Spacer()
             statsSection
         }
         .padding(16)
         .background(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .fill(.background)
                 .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
         )
         .overlay(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .stroke(habit.isCompletedToday ? Color(habit.colorName).opacity(0.3) : Color.clear, lineWidth: 1)
         )
         .contextMenu {
             Button {
                 backfillDate = Date()
                 showBackfill = true
             } label: {
                 Label(T("Backfill Date"), systemImage: "calendar.badge.plus")
             }
         }
         .sheet(isPresented: $showBackfill) {
             NavigationStack {
                 VStack(spacing: 20) {
                     DatePicker(T("Select date"), selection: $backfillDate, in: ...Date(), displayedComponents: .date)
                         .datePickerStyle(.graphical)
                         .padding()
                     Button(T("Complete for this date")) {
                         let day = Calendar.current.startOfDay(for: backfillDate)
                         let completion = HabitCompletion(date: day)
                         habit.completions.append(completion)
                         try? context.save()
                         showBackfill = false
                     }
                     .buttonStyle(.borderedProminent)
                 }
                 .navigationTitle(T("Backfill"))
                 .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(T("Cancel")) { showBackfill = false } } }
             }
         }
     }
     
     private var checkButton: some View {
         Button {
             toggleCompletion()
         } label: {
             ZStack {
                 Circle()
                     .fill(habit.isCompletedToday ? Color(habit.colorName) : Color(.systemGray5))
                     .frame(width: 36, height: 36)
                     .overlay(
                         Image(systemName: "checkmark")
                             .font(.system(size: 14, weight: .bold))
                             .foregroundColor(habit.isCompletedToday ? .white : .clear)
                     )
                     .scaleEffect(animateCheck ? 1.2 : 1.0)
             }
         }
         .buttonStyle(.plain)
         .sensoryFeedback(.success, trigger: animateCheck)
     }
     
     private var infoSection: some View {
         VStack(alignment: .leading, spacing: 4) {
             HStack(spacing: 6) {
                 Image(systemName: habit.iconName)
                     .font(.caption)
                     .foregroundColor(Color(habit.colorName))
                 Text(habit.name)
                 .font(.body.weight(.medium))
                 .strikethrough(habit.isCompletedToday)
                 .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
                 }
             
             HStack(spacing: 6) {
                 Image(systemName: habit.frequency.systemImage)
                     .font(.caption2)
                 Text(verbatim: T(habit.frequency.rawValue))
                     .font(.caption)
             }
             .foregroundColor(.secondary)
         }
     }
     
     private var statsSection: some View {
         HStack(spacing: 16) {
             Button {
                 onShowDetail?(habit)
             } label: {
                 VStack(spacing: 2) {
                     HStack(spacing: 2) {
                         Image(systemName: "flame.fill")
                             .font(.caption2)
                             .foregroundStyle(habit.currentStreak > 0 ? .orange : .gray.opacity(0.3))
                         Text("\(habit.currentStreak)")
                             .font(.subheadline.weight(.semibold))
                     }
                     Text(verbatim: T("streak"))
                         .font(.caption2)
                         .foregroundColor(.secondary)
                 }
             }
             .buttonStyle(.plain)
             
             // Weekly progress ring
             Button {
                 onShowDetail?(habit)
             } label: {
                 ZStack {
                     Circle()
                         .stroke(Color(.systemGray5), lineWidth: 3)
                         .frame(width: 28, height: 28)
                     Circle()
                         .trim(from: 0, to: habit.weeklyCompletionRate)
                         .stroke(Color(habit.colorName), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                         .frame(width: 28, height: 28)
                         .rotationEffect(.degrees(-90))
                 }
             }
             .buttonStyle(.plain)
         }
     }
     
     private func toggleCompletion() {
         let today = Calendar.current.startOfDay(for: Date())
         if !habit.canRepeatDaily && habit.isCompletedToday { return }
         let completion = HabitCompletion(date: today)
         habit.completions.append(completion)
        try? context.save()
         withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
             animateCheck.toggle()
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
             withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                 animateCheck = false
             }
         }
     }
 }

