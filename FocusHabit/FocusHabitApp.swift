 import SwiftUI
 import SwiftData
 
 @main
 struct FocusHabitApp: App {
     let container: ModelContainer
     
     init() {
         do {
             let schema = Schema([Habit.self, HabitCompletion.self])
             let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
             container = try ModelContainer(for: schema, configurations: config)
         } catch {
             fatalError("Failed to initialize ModelContainer: \(error)")
         }
     }
     
     var body: some Scene {
         WindowGroup {
             ContentView()
         }
         .modelContainer(container)
     }
 }
