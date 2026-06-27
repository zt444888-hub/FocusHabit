 import SwiftUI
 import SwiftData
 
 struct ContentView: View {
     @State private var selectedTab = 0
     @Environment(\.modelContext) private var context
     
     var body: some View {
         TabView(selection: $selectedTab) {
             HabitListView()
                 .tabItem {
                     Label("Habits", systemImage: "checklist")
                 }
                 .tag(0)
             
             FocusTimerView()
                 .tabItem {
                     Label("Focus", systemImage: "timer")
                 }
                 .tag(1)
             
             SettingsView()
                 .tabItem {
                     Label("Settings", systemImage: "gear")
                 }
                 .tag(2)
         }
         .tint(.orange)
     }
 }
 
 #Preview {
     ContentView()
         .modelContainer(for: Habit.self, inMemory: true)
 }
