 import SwiftUI
 
 struct WeekCalendarView: View {
     var habits: [Habit]
     @State private var selectedDate = Date()
     
     private let calendar = Calendar.current
     private let dateFormatter: DateFormatter = {
         let f = DateFormatter()
         f.dateFormat = "d"
         return f
     }()
     private let weekdayFormatter: DateFormatter = {
         let f = DateFormatter()
         f.dateFormat = "EEE"
         return f
     }()
     
     var body: some View {
         VStack(spacing: 12) {
             HStack {
                 Text(verbatim: T("This Week"))
                     .font(.subheadline.weight(.semibold))
                     .foregroundColor(.secondary)
                 Spacer()
                 Text(String(format: T("%d habits"), habitCompletionCount(for: selectedDate)))
                     .font(.caption)
                     .foregroundColor(.secondary)
             }
             
             HStack(spacing: 0) {
                 ForEach(daysOfWeek, id: \.self) { date in
                     dayColumn(for: date)
                 }
             }
         }
         .padding(16)
         .background(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .fill(.background)
                 .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
         )
     }
     
     private var daysOfWeek: [Date] {
         let today = calendar.startOfDay(for: Date())
         let weekday = calendar.component(.weekday, from: today)
         let firstWeekday = calendar.firstWeekday
         let daysOffset = (weekday - firstWeekday + 7) % 7
         let weekStart = calendar.date(byAdding: .day, value: -daysOffset, to: today) ?? today
         return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
     }
     
     private func dayColumn(for date: Date) -> some View {
         let isToday = calendar.isDateInToday(date)
         let completed = habits.filter { h in
             h.completions.contains { c in
                 calendar.isDate(c.date, inSameDayAs: date) && c.isCompleted
             }
         }.count
         let total = habits.count
         
         return VStack(spacing: 6) {
             Text(weekdayFormatter.string(from: date).prefix(1).uppercased())
                 .font(.system(size: 11, weight: .medium))
                 .foregroundColor(isToday ? .brand : .secondary)
             
             ZStack {
                 if isToday {
                     Circle()
                         .fill(Color.brand.opacity(0.12))
                         .frame(width: 32, height: 32)
                 }
                 Text(dateFormatter.string(from: date))
                     .font(.system(size: 15, weight: isToday ? .bold : .regular))
                     .foregroundColor(isToday ? .brand : .primary)
             }
             
             if total > 0 {
                 // let fraction = ... unused
                 VStack(spacing: 2) {
                     ForEach(0..<min(3, total), id: \.self) { i in
                         Circle()
                             .fill(i < completed ? Color.brand : Color(.systemGray5))
                             .frame(width: 5, height: 5)
                     }
                 }
             }
         }
         .frame(maxWidth: .infinity)
         .onTapGesture {
             withAnimation(.spring(response: 0.3)) {
                 selectedDate = date
             }
         }
     }
     
     private func habitCompletionCount(for date: Date) -> Int {
         return habits.filter { h in
             h.completions.contains { c in
                 calendar.isDate(c.date, inSameDayAs: date) && c.isCompleted
             }
         }.count
     }
 }
