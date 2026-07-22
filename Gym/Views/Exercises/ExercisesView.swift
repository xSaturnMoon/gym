import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""
    @State private var selectedExercise: Exercise?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscles.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categoryPicker
                    exerciseList
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Esercizi")
            .searchable(text: $searchText, prompt: "Cerca esercizio o muscolo")
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        selectedCategory = nil
                    } label: {
                        GlassPill(title: "Tutti", isSelected: selectedCategory == nil)
                    }
                    .buttonStyle(.plain)

                    ForEach(ExerciseCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            GlassPill(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var exerciseList: some View {
        GlassEffectContainer(spacing: 12) {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    Button {
                        selectedExercise = exercise
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: exercise.category.icon)
                                .font(.title3)
                                .foregroundStyle(.accent)
                                .frame(width: 40, height: 40)
                                .glassEffect(.regular.tint(.accentColor.opacity(0.15)), in: .circle)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(exercise.muscles.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            DifficultyBadge(level: exercise.difficulty)
                        }
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let videoID = exercise.youtubeVideoID {
                        YouTubeThumbnailView(videoID: videoID, videoURL: exercise.videoURL)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            DifficultyBadge(level: exercise.difficulty)
                            if !exercise.equipment.isEmpty {
                                Text(exercise.equipment.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(exercise.muscles.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    detailSection(title: "Istruzioni", icon: "text.alignleft", content: exercise.instructions)
                    detailSection(title: "Errori comuni", icon: "exclamationmark.triangle", content: exercise.commonMistakes)

                    if exercise.easierVariantName != nil || exercise.harderVariantName != nil {
                        variantsSection
                    }

                    channelSuggestion
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private func detailSection(title: String, icon: String, content: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.headline)
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var variantsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Varianti", systemImage: "arrow.up.arrow.down")
                    .font(.headline)
                if let easier = exercise.easierVariantName {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                        Text("Più facile: \(easier)")
                            .font(.subheadline)
                    }
                }
                if let harder = exercise.harderVariantName {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Più difficile: \(harder)")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var channelSuggestion: some View {
        GlassCard(tint: .blue.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Canali consigliati", systemImage: "play.tv")
                    .font(.headline)
                Text(exercise.category.suggestedChannels)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Puoi sostituire il video modificando il campo videoURL nel codice sorgente.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
