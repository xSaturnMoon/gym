import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var engine: WorkoutEngine?
    @State private var todayDay: PlannedDay?
    @State private var showGuidedWorkout = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 24) {
                    VStack(spacing: 20) {
                        headerSection
                        streakCard
                        if let day = todayDay {
                            workoutCard(for: day)
                        } else {
                            EmptyStateView(
                                icon: "calendar.badge.exclamationmark",
                                title: "Nessun allenamento oggi",
                                message: "Seleziona un piano attivo nella sezione Programma oppure goditi il giorno di riposo."
                            )
                        }
                    }
                    .padding()
                }
            }
            .background(backgroundGradient)
            .navigationTitle("Oggi")
            .onAppear { refresh() }
            .fullScreenCover(isPresented: $showGuidedWorkout) {
                if let day = todayDay {
                    GuidedWorkoutView(plannedDay: day)
                }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        SectionHeader(
            title: greeting,
            subtitle: formattedDate
        )
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak attuale")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(profile?.currentStreak ?? 0) giorni")
                    .font(.title.bold())
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
                .glassEffect(.regular.tint(.orange.opacity(0.3)), in: .circle)
                .frame(width: 56, height: 56)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func workoutCard(for day: PlannedDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.name)
                        .font(.title3.bold())
                    Text(day.dayType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                dayTypeIcon(for: day.dayType)
            }

            if day.dayType == .workout {
                let exercises = day.sortedExercises
                Text("\(exercises.count) esercizi · ~\(estimatedMinutes(for: day)) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(exercises.prefix(4), id: \.exerciseID) { planned in
                        if let exercise = engine?.exercise(for: planned) {
                            HStack {
                                Image(systemName: exercise.category.icon)
                                    .foregroundStyle(.accent)
                                    .frame(width: 24)
                                Text(exercise.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(setDescription(for: planned))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if exercises.count > 4 {
                        Text("+ altri \(exercises.count - 4) esercizi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    HapticService.medium()
                    showGuidedWorkout = true
                } label: {
                    Label("Inizia allenamento guidato", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            } else {
                Text(recoveryMessage(for: day.dayType))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if day.dayType == .activeRecovery {
                    Button {
                        HapticService.light()
                        showGuidedWorkout = true
                    } label: {
                        Label("Avvia sessione di recupero", systemImage: "leaf.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(.accentColor.opacity(0.1)), in: .rect(cornerRadius: 20))
    }

    private func dayTypeIcon(for type: DayType) -> some View {
        let (icon, color): (String, Color) = switch type {
        case .workout: ("figure.run", .accentColor)
        case .activeRecovery: ("leaf.fill", .green)
        case .rest: ("moon.fill", .purple)
        }
        return Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
            .glassEffect(.regular.tint(color.opacity(0.2)), in: .circle)
            .frame(width: 48, height: 48)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Buongiorno"
        case 12..<18: return "Buon pomeriggio"
        default: return "Buonasera"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: .now).capitalized
    }

    private func setDescription(for planned: PlannedExercise) -> String {
        if let duration = planned.durationSeconds {
            return "\(planned.sets)×\(duration)s"
        }
        return "\(planned.sets)×\(planned.reps ?? 0)"
    }

    private func estimatedMinutes(for day: PlannedDay) -> Int {
        let total = day.sortedExercises.reduce(0) { sum, planned in
            let workTime = (planned.durationSeconds ?? (planned.reps ?? 10) * 3) * planned.sets
            let restTime = planned.restSeconds * max(0, planned.sets - 1)
            return sum + workTime + restTime
        }
        return max(15, total / 60)
    }

    private func recoveryMessage(for type: DayType) -> String {
        switch type {
        case .rest:
            "Giorno di riposo. Il recupero è parte del progresso: i muscoli crescono quando riposi."
        case .activeRecovery:
            "Recupero attivo: mobilità leggera e stretching per mantenere il corpo fluido."
        case .workout:
            ""
        }
    }

    private func refresh() {
        engine = WorkoutEngine(modelContext: modelContext)
        todayDay = engine?.todayPlannedDay()
    }
}
