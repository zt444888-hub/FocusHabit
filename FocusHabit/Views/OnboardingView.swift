import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            Image(systemName: "checklist.unchecked")
                .font(.system(size: 60))
                .foregroundColor(.brand)
                .padding(.bottom, 24)

            // App name
            Text(verbatim: T("FocusHabit Pro"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(verbatim: T("Habit Tracker & Pomodoro Timer"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)

            // Divider
            Rectangle()
                .fill(Color.brand.opacity(0.3))
                .frame(width: 40, height: 3)
                .cornerRadius(1.5)
                .padding(.bottom, 32)

            // Get Started button
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Text(verbatim: T("Get Started"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(Color.brand, in: Capsule())
            }
            .padding(.bottom, 16)

            // Skip
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Text(verbatim: T("Skip"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
