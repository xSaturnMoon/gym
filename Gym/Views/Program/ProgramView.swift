import SwiftUI
import SwiftData

struct ProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.name) private var plans: [WorkoutPlan]
    @Query private var profiles: [UserProfile]

    @State private var engine: WorkoutEngine?
    @State private var selectedPlan: WorkoutPlan?
    @State private var showPlanDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 20) {
                    VStack(spacing: 20) {
                        SectionHeader(
                            title: "Il tuo programma",
                            subtitle: "Scegli un piano adatto al tuo livello e modificalo come preferisci."
                        )

                        ForEach(plans) { plan in
                            planCard(plan)
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Programma")
            .onAppear { engine = WorkoutEngine(modelContext: modelContext) }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
    }

    private func planCard(_ plan: WorkoutPlan) -> some View {
        let isActive = profiles.first?.activePlanID == plan.id || plan.isActive

        return Button {
            selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(plan.planType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    DifficultyBadge(level: plan.level)
                }

                HStack(spacing: 16) {
                    MetricChip(icon: "calendar", text: plan.planType.rawValue)
                    MetricChip(icon: "figure.run", text: "\(workoutDaysCount(plan)) giorni attivi")
                }

                if isActive {
                    Label("Piano attivo", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Button {
                        engine?.setActivePlan(plan)
                        HapticService.success()
                    } label: {
                        Text("Attiva questo piano")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding()
            .glassEffect(
                isActive
                    ? .regular.tint(.green.opacity(0.15)).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: 20)
            )
        }
        .buttonStyle(.plain)
    }

    private func workoutDaysCount(_ plan: WorkoutPlan) -> Int {
        plan.days.filter { $0.dayType == .workout }.count
    }
}

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: WorkoutPlan

    @State private var engine: WorkoutEngine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(plan.sortedDays) { day in
                    DayRowView(day: day, engine: engine)
                }
                .onMove(perform: moveDay)
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .onAppear { engine = WorkoutEngine(modelContext: modelContext) }
        }
    }

    private func moveDay(from source: IndexSet, to destination: Int) {
        var days = plan.sortedDays
        days.move(fromOffsets: source, toOffset: destination)
        for (index, day) in days.enumerated() {
            day.orderIndex = index
        }
        try? modelContext.save()
    }
}

struct DayRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var day: PlannedDay
    var engine: WorkoutEngine?

    @State private var isExpanded = false

    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.name)
                        .font(.headline)
                        .strikethrough(day.isSkipped)
                    Text(day.dayType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                dayTypeBadge
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { isExpanded.toggle() } }

            if isExpanded && day.dayType != .rest {
                ForEach(day.sortedExercises, id: \.exerciseID) { planned in
                    if let exercise = engine?.exercise(for: planned) {
                        HStack {
                            Text(exercise.name)
                                .font(.subheadline)
                            Spacer()
                            if let duration = planned.durationSeconds {
                                Text("\(planned.sets)×\(duration)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(planned.sets)×\(planned.reps ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if day.dayType == .workout {
                HStack {
                    Button(day.isSkipped ? "Ripristina" : "Salta giorno") {
                        if day.isSkipped {
                            engine?.unskipDay(day)
                        } else {
                            engine?.skipDay(day)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.glass)

                    Spacer()

                    Button("Rigenera") {
                        regenerateDay()
                    }
                    .font(.caption)
                    .buttonStyle(.glass)
                }
            }
        }
    }

    private var dayTypeBadge: some View {
        let (icon, color): (String, Color) = switch day.dayType {
        case .workout: ("figure.run", .accentColor)
        case .activeRecovery: ("leaf.fill", .green)
        case .rest: ("moon.fill", .purple)
        }
        return Image(systemName: icon)
            .foregroundStyle(color)
    }

    private func regenerateDay() {
        let alternatives: [String] = [
            "bodyweight-squat", "push-up", "plank", "glute-bridge",
            "reverse-lunge", "mountain-climber", "dead-bug", "superman"
        ]
        day.exercises.removeAll()
        let shuffled = alternatives.shuffled().prefix(4)
        day.exercises = shuffled.enumerated().map { index, id in
            let lib = ExerciseLibrary.exercise(byID: id)
            return PlannedExercise(
                exerciseID: id,
                orderIndex: index,
                sets: 3,
                reps: lib?.defaultReps,
                durationSeconds: lib?.defaultDurationSeconds,
                restSeconds: lib?.defaultRestSeconds ?? 60
            )
        }
        day.isSkipped = false
        try? modelContext.save()
        HapticService.success()
    }
}
