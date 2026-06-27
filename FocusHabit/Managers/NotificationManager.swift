 import UserNotifications
 
 struct NotificationManager {
     static func requestAuthorization() {
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             if let error = error {
                 print("Notification permission error: \(error.localizedDescription)")
             }
         }
     }
     
     static func scheduleHabitReminder(for habit: Habit) {
         guard let reminderTime = habit.reminderTime else { return }
         let content = UNMutableNotificationContent()
         content.title = habit.name
         content.body = "Don't forget your habit today!"
         content.sound = .default
         
         let calendar = Calendar.current
         let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
         let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
         let request = UNNotificationRequest(identifier: habit.id, content: content, trigger: trigger)
         UNUserNotificationCenter.current().add(request)
     }
     
     static func removeHabitReminder(for habit: Habit) {
         UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id])
     }
 }
