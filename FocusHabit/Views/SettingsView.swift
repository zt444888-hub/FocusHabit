import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allHabits: [Habit]
    @State private var showResetAlert = false
    @State private var showPaywall = false
    @State private var showReport = false
    @State private var showArchived = false
    @State private var showPresets = false
    @State private var showReminders = false
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("appLanguage") private var appLanguage = ""
    @State private var showLanguageAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text(verbatim: T("FocusHabit"))
                            .font(.title2.weight(.bold))
                        Text(verbatim: T("Build habits that stick."))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Section {
                    if StoreManager.shared.isPremium {
                        HStack {
                            Label(T("Premium Active"), systemImage: "checkmark.seal.fill")
                                .foregroundColor(.brand)
                            Spacer()
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label(T("Upgrade to Premium"), systemImage: "crown.fill")
                                    .foregroundColor(.brand)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(verbatim: T("Subscription"))
                }

                Section(T("Your Stats")) {
                    let totalHabits = allHabits.count
                    let activeHabits = allHabits.filter { !$0.isArchived }.count
                    let totalCompletions = allHabits.reduce(0) { $0 + $1.totalCompletions }

                    StatRow(icon: "circle.grid.3x3.fill", label: T("Total Habits"), value: "\(totalHabits)")
                    StatRow(icon: "checkmark.circle", label: T("Active Habits"), value: "\(activeHabits)")
                    StatRow(icon: "star.fill", label: T("Total Completions"), value: "\(totalCompletions)")
                }

                Button {
                    if StoreManager.shared.canReports { showReport = true } else { showPaywall = true }
                } label: {
                    HStack {
                        Label(T("Weekly Report"), systemImage: "chart.bar.xaxis")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(T("Tools")) {
                    Button {
                        showPresets = true
                    } label: {
                        Label(T("Focus Presets"), systemImage: "timer")
                            .foregroundColor(.primary)
                    }
                    Button {
                        showReminders = true
                    } label: {
                        Label(T("Reminders"), systemImage: "bell")
                            .foregroundColor(.primary)
                    }
                    Button {
                        shareURL = generateExportURL()
                        showShareSheet = true
                    } label: {
                        Label(T("Export Data"), systemImage: "square.and.arrow.up")
                            .foregroundColor(.primary)
                    }
                }

                Section {
                    Toggle(T("Show Archived Habits"), isOn: $showArchived)
                } header: {
                    Text(verbatim: T("Habits"))
                }

                Section(T("Appearance")) {
                    Toggle(T("Dark Mode"), isOn: $darkMode)
                }

                Section(T("Language")) {
                    Picker(T("App Language"), selection: $appLanguage) {
                        Text(verbatim: T("System")).tag("")
                        Text(verbatim: T("English")).tag("en")
                        Text(verbatim: T("中文")).tag("zh-Hans")
                        Text(verbatim: T("日本語")).tag("ja")
                        Text(verbatim: T("Français")).tag("fr")
                        Text(verbatim: T("Español")).tag("es")
                        Text(verbatim: T("Deutsch")).tag("de")
                        Text(verbatim: T("한국어")).tag("ko")
                    }
                    .onChange(of: appLanguage) { _, newValue in
                        if newValue.isEmpty {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        }
                        UserDefaults.standard.synchronize()
                        showLanguageAlert = true
                    }
                }

                Section(T("About")) {
                    HStack {
                        Text(verbatim: T("Version"))
                        Spacer()
                        Text(verbatim: T("1.0"))
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXXX?action=write-review")!) {
                        HStack {
                            Label(T("Rate on App Store"), systemImage: "star")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(T("Settings"))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showReport) {
                ReportView()
            }
            .sheet(isPresented: $showArchived) {
                ArchivedHabitsView()
            }
            .sheet(isPresented: $showPresets) {
                NavigationStack { PresetListView() }
            }
            .sheet(isPresented: $showReminders) {
                ReminderListView()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareURL].compactMap { $0 })
            }
            .alert(T("Reset All Data?"), isPresented: $showResetAlert) {
                Button(T("Cancel"), role: .cancel) { }
                Button(T("Delete"), role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text(verbatim: T("This will permanently delete all your habits and history."))
            }
            .alert(T("Language Changed"), isPresented: $showLanguageAlert) {
                Button(T("OK")) { }
            } message: {
                Text(verbatim: T("The language will update after restarting the app."))
            }
        }
    }

    private func generateExportURL() -> URL? {
        struct ExportData: Encodable {
            let habits: [ExportHabit]
            let exportDate: Date
        }
        struct ExportHabit: Encodable {
            let name: String
            let frequency: String
            let streak: Int
            let totalCompletions: Int
            let completions: [ExportCompletion]
        }
        struct ExportCompletion: Encodable {
            let date: Date
        }
        let export = ExportData(
            habits: allHabits.map { h in
                ExportHabit(
                    name: h.name, frequency: h.frequency.rawValue,
                    streak: h.currentStreak, totalCompletions: h.totalCompletions,
                    completions: h.completions.filter(\.isCompleted).map { ExportCompletion(date: $0.date) }
                )
            },
            exportDate: Date()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(export) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FocusHabit_Export.json")
        try? data.write(to: url)
        return url
    }

    private func deleteAllData() {
        for habit in allHabits {
            context.delete(habit)
        }
        try? context.save()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
        }
    }
}

