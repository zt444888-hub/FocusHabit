 import SwiftUI
 import SwiftData
 
 struct HabitCardView: View {
     @Bindable var habit: Habit
     @Environment(\.modelContext) private var context
     @State private var animateCheck = false
     
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
                 .stroke(habit.isCompletedToday ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
         )
     }
     
     private var checkButton: some View {
         Button {
             toggleCompletion()
         } label: {
             ZStack {
                 Circle()
                     .fill(habit.isCompletedToday ? Color.orange : Color(.systemGray5))
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
             Text(habit.name)
                 .font(.body.weight(.medium))
                 .strikethrough(habit.isCompletedToday)
                 .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
             
             HStack(spacing: 6) {
                 Image(systemName: habit.frequency.systemImage)
                     .font(.caption2)
                 Text(habit.frequency.rawValue)
                     .font(.caption)
             }
             .foregroundColor(.secondary)
         }
     }
     
     private var statsSection: some View {
         HStack(spacing: 16) {
             VStack(spacing: 2) {
                 HStack(spacing: 2) {
                     Image(systemName: "flame.fill")
                         .font(.caption2)
                         .foregroundStyle(habit.currentStreak > 0 ? .orange : .gray.opacity(0.3))
                     Text("\(habit.currentStreak)")
                         .font(.subheadline.weight(.semibold))
                 }
                 Text("streak")
                     .font(.caption2)
                     .foregroundColor(.secondary)
             }
             
             // Weekly progress ring
             ZStack {
                 Circle()
                     .stroke(Color(.systemGray5), lineWidth: 3)
                     .frame(width: 28, height: 28)
                 Circle()
                     .trim(from: 0, to: habit.weeklyCompletionRate)
                     .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                     .frame(width: 28, height: 28)
                     .rotationEffect(.degrees(-90))
             }
         }
     }
     
     private func toggleCompletion() {
         let today = Calendar.current.startOfDay(for: Date())
         if let existing = habit.completions.first(where: {
             Calendar.current.startOfDay(for: $0.date) == today
         }) {
             context.delete(existing)
            try? context.save()
         } else {
             let completion = HabitCompletion(date: today)
             habit.completions.append(completion)
            try? context.save()
         }
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

