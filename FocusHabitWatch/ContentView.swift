import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "checklist")
                }
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
        }
    }
}