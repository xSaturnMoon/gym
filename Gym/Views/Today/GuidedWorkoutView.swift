import SwiftUI
import SwiftData

struct GuidedWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plannedDay: PlannedDay

    @StateObject private var timer = WorkoutTimer()
    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var workoutStartTime = Date()
    @State private var showCompletionSheet = false
    @State private var sessionNotes = ""
    @State private var perceivedDifficulty = 3
    @State private var engine: WorkoutEngine?

    private var exercises: [PlannedExercise] { plannedDay.sortedExercises }
    private var currentPlanned: PlannedExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                if let planned = currentPlanned, let exercise = engine?.exercise(for: planned) {
                    VStack(spacing: 0) {
                        progressBar
                        ScrollView {
                            VStack(spacing: 24) {
                                exerciseHeader(exercise: exercise, planned: planned)
                                timerSection(planned: planned, exercise: exercise)
                                exerciseDetails(exercise: exercise)
                            }
                            .padding()
                        }
                        bottomControls(planned: planned, exercise: exercise)
                    }
                } else {
                    completionView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Esci") { dismiss() }
                        .buttonStyle(.glass)
                }
                ToolbarItem(placement: .principal) {
                    Text(plannedDay.name)
                        .font(.headline)
                }
            }
            .sheet(isPresented: $showCompletionSheet) {
                completionSheet
            }
            .onAppear {
                engine = WorkoutEngine(modelContext: modelContext)
                workoutStartTime = .now
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.08, green: 0.05, blue: 0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var progressBar: some View {
        let progress = Double(currentExerciseIndex) / Double(max(exercises.count, 1))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(.accent)
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func exerciseHeader(exercise: Exercise, planned: PlannedExercise) -> some View {
        VStack(spacing: 12) {
            Text("Esercizio \(currentExerciseIndex + 1) di \(exercises.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(exercise.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                DifficultyBadge(level: exercise.difficulty)
                Text("Serie \(currentSet)/\(planned.sets)")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
        }
    }

    private func timerSection(planned: PlannedExercise, exercise: Exercise) -> some View {
        GlassEffectContainer {
            VStack(spacing: 16) {
                if isResting {
                    Text("RECUPERO")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                    Text(timer.formattedTime)
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .monospacedDigit()
                    Button("Salta recupero") {
                        timer.skipRest()
                    }
                    .buttonStyle(.glass)
                } else if exercise.metric == .time || planned.durationSeconds != nil {
                    Text("TEMPO")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.accent)
                    Text(timer.isRunning ? timer.formattedTime : formatDuration(planned.durationSeconds ?? 30))
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("RIPETIZIONI")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.accent)
                    Text("\(planned.reps ?? 12)")
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .glassEffect(.regular.tint(.accentColor.opacity(0.1)), in: .rect(cornerRadius: 24))
        }
    }

    private func exerciseDetails(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let videoID = exercise.youtubeVideoID {
                YouTubeThumbnailView(videoID: videoID, videoURL: exercise.videoURL)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Istruzioni", systemImage: "text.alignleft")
                        .font(.headline)
                    Text(exercise.instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func bottomControls(planned: PlannedExercise, exercise: Exercise) -> some View {
        HStack(spacing: 16) {
            if currentExerciseIndex > 0 || currentSet > 1 {
                GlassIconButton(systemName: "backward.fill") {
                    goBack()
                }
            }

            Spacer()

            if isResting {
                EmptyView()
            } else if exercise.metric == .time || planned.durationSeconds != nil {
                Button {
                    startTimedExercise(planned: planned)
                } label: {
                    Label(timer.isRunning ? "Pausa" : "Avvia", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .frame(minWidth: 140)
                }
                .buttonStyle(.glassProminent)
            } else {
                Button {
                    completeSet(planned: planned)
                } label: {
                    Label("Serie completata", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(minWidth: 140)
                }
                .buttonStyle(.glassProminent)
            }

            Spacer()
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 0))
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .glassEffect(.regular.tint(.green.opacity(0.3)), in: .circle)
                .frame(width: 120, height: 120)

            Text("Allenamento completato!")
                .font(.title.bold())

            Text("Ottimo lavoro. Ogni sessione ti avvicina ai tuoi obiettivi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Salva e chiudi") {
                showCompletionSheet = true
            }
            .buttonStyle(.glassProminent)
        }
        .padding()
    }

    private var completionSheet: some View {
        NavigationStack {
            Form {
                Section("Come ti sei sentito?") {
                    Picker("Difficoltà percepita", selection: $perceivedDifficulty) {
                        Text("Facile").tag(1)
                        Text("Moderato").tag(2)
                        Text("Normale").tag(3)
                        Text("Impegnativo").tag(4)
                        Text("Molto duro").tag(5)
                    }
                }
                Section("Note (opzionale)") {
                    TextField("Come è andata la sessione?", text: $sessionNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Riepilogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func startTimedExercise(planned: PlannedExercise) {
        if timer.isRunning {
            timer.pause()
        } else if timer.phase == .exercise && timer.remainingSeconds > 0 {
            timer.resume()
        } else {
            let duration = planned.durationSeconds ?? 30
            timer.startExercise(duration: duration, set: currentSet, total: planned.sets) {
                completeSet(planned: planned)
            }
            HapticService.light()
        }
    }

    private func completeSet(planned: PlannedExercise) {
        HapticService.success()

        if currentSet < planned.sets {
            isResting = true
            timer.startRest(duration: planned.restSeconds) {
                isResting = false
                currentSet += 1
            }
        } else {
            advanceToNextExercise()
        }
    }

    private func advanceToNextExercise() {
        currentSet = 1
        isResting = false
        timer.stop()

        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            HapticService.medium()
        } else {
            currentExerciseIndex = exercises.count
            HapticService.success()
        }
    }

    private func goBack() {
        timer.stop()
        isResting = false
        if currentSet > 1 {
            currentSet -= 1
        } else if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            currentSet = exercises[currentExerciseIndex].sets
        }
    }

    private func saveAndDismiss() {
        let duration = Int(Date().timeIntervalSince(workoutStartTime) / 60)
        engine?.completeWorkout(
            plannedDay: plannedDay,
            durationMinutes: max(1, duration),
            notes: sessionNotes.isEmpty ? nil : sessionNotes,
            perceivedDifficulty: perceivedDifficulty
        )
        dismiss()
    }

    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct YouTubeThumbnailView: View {
    let videoID: String
    let videoURL: String
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: videoURL) {
                openURL(url)
            }
        } label: {
            ZStack {
                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(.gray.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomLeading) {
            Label("Guarda dimostrazione", systemImage: "play.rectangle.fill")
                .font(.caption)
                .padding(8)
                .glassEffect(.regular, in: .capsule)
                .padding(8)
        }
    }
}
