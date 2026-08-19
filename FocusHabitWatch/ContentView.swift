import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HabitListView()
                .tabItem {
                    Label(WT("Habits"), systemImage: "checklist")
                }
            TimerView()
                .tabItem {
                    Label(WT("Timer"), systemImage: "timer")
                }
        }
    }
}