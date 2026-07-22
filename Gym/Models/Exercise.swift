import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var categoryRaw: String
    var muscles: [String]
    var difficultyRaw: String
    var instructions: String
    var commonMistakes: String
    var videoURL: String
    var easierVariantName: String?
    var harderVariantName: String?
    var equipment: [String]
    var defaultSets: Int
    var defaultReps: Int?
    var defaultDurationSeconds: Int?
    var defaultRestSeconds: Int
    var metricRaw: String

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .core }
        set { categoryRaw = newValue.rawValue }
    }

    var difficulty: DifficultyLevel {
        get { DifficultyLevel(rawValue: difficultyRaw) ?? .beginner }
        set { difficultyRaw = newValue.rawValue }
    }

    var metric: ExerciseMetric {
        get { ExerciseMetric(rawValue: metricRaw) ?? .reps }
        set { metricRaw = newValue.rawValue }
    }

    var youtubeVideoID: String? {
        guard let url = URL(string: videoURL) else { return nil }
        if let host = url.host, host.contains("youtu.be") {
            return url.lastPathComponent
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoID
        }
        return nil
    }

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        muscles: [String],
        difficulty: DifficultyLevel,
        instructions: String,
        commonMistakes: String,
        videoURL: String,
        easierVariantName: String? = nil,
        harderVariantName: String? = nil,
        equipment: [String] = [],
        defaultSets: Int = 3,
        defaultReps: Int? = 12,
        defaultDurationSeconds: Int? = nil,
        defaultRestSeconds: Int = 60,
        metric: ExerciseMetric = .reps
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.muscles = muscles
        self.difficultyRaw = difficulty.rawValue
        self.instructions = instructions
        self.commonMistakes = commonMistakes
        self.videoURL = videoURL
        self.easierVariantName = easierVariantName
        self.harderVariantName = harderVariantName
        self.equipment = equipment
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultDurationSeconds = defaultDurationSeconds
        self.defaultRestSeconds = defaultRestSeconds
        self.metricRaw = metric.rawValue
    }
}
