import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("userGoal") private var userGoal = ""
    @State private var goalInput = ""
    @State private var showContent = false

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

            // Goal input
            VStack(spacing: 8) {
                Text(verbatim: T("What's your goal?"))
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField(T("e.g. Learn to code, Get fit, Read more"), text: $goalInput)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brand.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .autocapitalization(.sentences)
            }
            .padding(.bottom, 32)

            // Get Started button
    Button {
        hasSeenOnboarding = true
        if !goalInput.trimmingCharacters(in: .whitespaces).isEmpty {
            userGoal = goalInput.trimmingCharacters(in: .whitespaces)
        }
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
