import SwiftUI
import SwiftData

@main
struct FocusHabitApp: App {
    @State private var container: ModelContainer?
    @State private var loadError: String?
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("darkMode") private var darkMode = false

    init() {
        do {
            let container = try ModelContainer(for: Habit.self, HabitCompletion.self, FocusSession.self)
            _container = State(initialValue: container)
        } catch {
            _loadError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    Group {
                        if hasSeenOnboarding {
                            ContentView()
                        } else {
                            OnboardingView()
                        }
                    }
                    .modelContainer(container)
                } else {
                    StartupErrorView(message: loadError ?? "Unknown error", onRetry: retry)
                }
            }
            .preferredColorScheme(darkMode ? .dark : .light)
        }
    }

    private func retry() {
        do {
            let container = try ModelContainer(for: Habit.self, HabitCompletion.self, FocusSession.self)
            self.container = container
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }
}

private struct StartupErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(T("Something went wrong"))
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(T("Retry"), action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(.brand)
        }
        .padding()
    }
}
