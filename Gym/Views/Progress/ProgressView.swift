import SwiftUI
import SwiftData
import Charts

struct GymProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    @State private var engine: WorkoutEngine?
    @State private var selectedPeriod: Period = .week

    enum Period: String, CaseIterable {
        case week = "Settimana"
        case month = "Mese"
    }

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 20) {
                    VStack(spacing: 20) {
                        photoProgressEntry
                        statsOverview
                        streakHeatmap
                        periodPicker
                        chartSection
                        recentSessions
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.08, green: 0.05, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Progressi")
            .onAppear { engine = WorkoutEngine(modelContext: modelContext) }
        }
    }

    private var photoProgressEntry: some View {
        NavigationLink {
            PhotoProgressHubView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular.tint(.accentColor.opacity(0.15)), in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Foto Progressi")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Scatta, confronta e analizza i cambiamenti fisici")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var statsOverview: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Streak",
                value: "\(profile?.currentStreak ?? 0)",
                subtitle: "Record: \(profile?.longestStreak ?? 0)",
                icon: "flame.fill",
                color: .orange
            )
            statCard(
                title: "Sessioni",
                value: "\(completedSessions.count)",
                subtitle: "Totali",
                icon: "checkmark.circle.fill",
                color: .green
            )
            statCard(
                title: "Minuti",
                value: "\(totalMinutes)",
                subtitle: "Allenati",
                icon: "clock.fill",
                color: .blue
            )
        }
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(color.opacity(0.1)), in: .rect(cornerRadius: 16))
    }

    private var streakHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendario allenamenti")
                .font(.headline)

            let days = last30Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    let hasWorkout = completedSessions.contains {
                        Calendar.current.isDate($0.date, inSameDayAs: date)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(hasWorkout ? Color.accentColor : Color.white.opacity(0.08))
                        .frame(height: 28)
                        .overlay {
                            if Calendar.current.isDateInToday(date) {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            }
                        }
                }
            }

            HStack {
                Text("Meno")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 12, height: 12)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: 12, height: 12)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                Text("Più")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var periodPicker: some View {
        Picker("Periodo", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allenamenti per \(selectedPeriod.rawValue.lowercased())")
                .font(.headline)

            Chart(chartData) { item in
                BarMark(
                    x: .value("Giorno", item.label),
                    y: .value("Sessioni", item.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessioni recenti")
                .font(.headline)

            if completedSessions.isEmpty {
                Text("Nessuna sessione completata. Inizia il tuo primo allenamento dalla scheda Oggi!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(completedSessions.prefix(10)) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.workoutName)
                                .font(.subheadline.weight(.medium))
                            Text(session.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(session.durationMinutes) min")
                                .font(.caption)
                            if let difficulty = session.perceivedDifficulty {
                                Text(difficultyLabel(difficulty))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if session.notes != nil {
                        Text(session.notes ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    Divider().opacity(0.3)
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var totalMinutes: Int {
        completedSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var last30Days: [Date] {
        let calendar = Calendar.current
        return (0..<28).compactMap { offset in
            calendar.date(byAdding: .day, value: -(27 - offset), to: calendar.startOfDay(for: .now))
        }
    }

    private struct ChartItem: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
    }

    private var chartData: [ChartItem] {
        let calendar = Calendar.current
        let count = selectedPeriod == .week ? 7 : 30
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = selectedPeriod == .week ? "EEE" : "d"

        return (0..<count).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: .now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let daySessions = completedSessions.filter { $0.date >= dayStart && $0.date < dayEnd }
            return ChartItem(label: formatter.string(from: date), count: daySessions.count)
        }
    }

    private func difficultyLabel(_ value: Int) -> String {
        switch value {
        case 1: "Facile"
        case 2: "Moderato"
        case 3: "Normale"
        case 4: "Impegnativo"
        default: "Molto duro"
        }
    }
}
