import SwiftUI
import SwiftData

struct HabitListView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \.sortOrder)
    private var habits: [Habit]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var editingHabit: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    habitsSection
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddHabitView()
            }
            .sheet(item: $editingHabit) { habit in
                AddHabitView(habit: habit)
            }
            .onAppear {
                NotificationManager.requestAuthorization()
                refreshWidgetData()
            }
            .onChange(of: habits.map(\.isCompletedToday)) { _, _ in
                refreshWidgetData()
            }
        }
    }

    private func refreshWidgetData() {
        WidgetDataWriter.updateWidgetData(for: habits)
    }

    private var headerSection: some View {
        WeekCalendarView(habits: habits)
            .padding(.top, 8)
    }

    private var habitsSection: some View {
        LazyVStack(spacing: 12) {
            if habits.isEmpty {
                emptyState
            } else {
                ForEach(habits) { habit in
                    HabitCardView(habit: habit)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    context.delete(habit)
                                try? context.save()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            editingHabit = habit
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.3))
            Text("Build your habits")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            Text("Start small. Stay consistent.\nAdd your first habit to begin.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddSheet = true
            } label: {
                Label("Add Habit", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.orange, in: Capsule())
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}


