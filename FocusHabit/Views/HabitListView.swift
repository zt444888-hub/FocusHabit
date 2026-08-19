import SwiftUI
import SwiftData

struct HabitListView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \.sortOrder)
    private var habits: [Habit]
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var editingHabit: Habit?
    @State private var detailHabit: Habit?
    @State private var showPaywall = false
    @State private var celebrationTrigger = 0
    @State private var celebrationStart: CGRect = .zero
    private var canAddMore: Bool {
        StoreManager.shared.isPremium || habits.count < StoreManager.shared.maxFreeHabits
    }

    var body: some View {
        NavigationStack {
            List {
                headerSection
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                if habits.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                ForEach(habits) { habit in
                    HabitCardView(habit: habit, onShowDetail: { detailHabit = $0 }, onCelebrate: { frame in
                        celebrationStart = frame
                        celebrationTrigger += 1
                    })
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                editingHabit = habit
                            } label: {
                                Label(T("Edit"), systemImage: "pencil")
                            }
                            .tint(.brand)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label(T("Delete"), systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Label(T("Delete"), systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(T("Habits"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if canAddMore {
                            showAddSheet = true
                        } else {
                            showPaywall = true
                        }
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
            .navigationDestination(item: $detailHabit) { habit in
                HabitDetailView(habit: habit)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .overlay {
                CelebrationOverlay(startFrame: celebrationStart, trigger: $celebrationTrigger)
            }
            .onAppear {
                refreshWidgetData()
            }
            .onChange(of: habits.map(\.isCompletedToday)) { _, _ in
                refreshWidgetData()
            }
        }
    }

    private func refreshWidgetData() {
        DataSync.refreshAll(habits: habits)
    }

    private func deleteHabit(_ habit: Habit) {
        HabitStore.delete(habit, context: context)
    }

    private var headerSection: some View {
        WeekCalendarView(habits: habits)
            .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.3))
            Text(verbatim: T("Build your habits"))
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            Text(verbatim: T("Start small. Stay consistent.\nAdd your first habit to begin."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if canAddMore {
                    showAddSheet = true
                } else {
                    showPaywall = true
                }
            } label: {
                Label(T("Add Habit"), systemImage: "plus")
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
