import SwiftUI
import SwiftData

@main
struct FocusHabitApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Habit.self, HabitCompletion.self, FocusSession.self)
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
