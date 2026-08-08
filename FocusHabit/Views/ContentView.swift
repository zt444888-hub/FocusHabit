 import SwiftUI
 import SwiftData
 
struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("appLanguage") private var appLanguage = ""
    @AppStorage("darkMode") private var darkMode = false
    @Environment(\.modelContext) private var context
    
    var body: some View {
         TabView(selection: $selectedTab) {
             HabitListView()
                 .tabItem {
                     Label(T("Habits"), systemImage: "checklist")
                 }
                 .tag(0)
             
             FocusTimerView()
                 .tabItem {
                     Label(T("Focus"), systemImage: "timer")
                 }
                 .tag(1)
             
             SettingsView()
                 .tabItem {
                     Label(T("Settings"), systemImage: "gear")
                 }
                 .tag(2)
        }
        .tint(.brand)
        .preferredColorScheme(darkMode ? .dark : .light)
        .id(appLanguage)
    }
 }
 
 #Preview {
     ContentView()
         .modelContainer(for: Habit.self, inMemory: true)
 }
