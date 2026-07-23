import Foundation
import SwiftData

@MainActor
final class DataController {
    let container: ModelContainer

    private static let schema = Schema([
        Exercise.self,
        WorkoutPlan.self,
        PlannedDay.self,
        PlannedExercise.self,
        WorkoutSession.self,
        CompletedExercise.self,
        CompletedSet.self,
        UserProfile.self,
        ProgressPhoto.self,
        ProgressAnalysisReport.self,
        ProgressPhotoSettings.self,
    ])

    private static let modelConfiguration = ModelConfiguration(schema: schema)

    static let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        ExerciseLibrary.seed(into: context)
        WorkoutPlansSeed.seed(into: context)
        context.insert(UserProfile())
        context.insert(ProgressPhotoSettings())
        return container
    }()

    init() {
        container = Self.makeContainer()
    }

    func seedIfNeeded() async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        ExerciseLibrary.seed(into: context)
        WorkoutPlansSeed.seed(into: context)

        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(profileDescriptor)) ?? []
        if profiles.isEmpty {
            let profile = UserProfile()
            profile.activePlanID = "plan-fullbody3-beginner"
            context.insert(profile)
        }

        let settingsDescriptor = FetchDescriptor<ProgressPhotoSettings>()
        let settings = (try? context.fetch(settingsDescriptor)) ?? []
        if settings.isEmpty {
            context.insert(ProgressPhotoSettings())
        }

        try? context.save()
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Aggiornamenti del modello SwiftData possono invalidare il DB locale.
            removePersistentStoreFiles()
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Impossibile inizializzare SwiftData: \(error)")
            }
        }
    }

    private static func removePersistentStoreFiles() {
        let fileManager = FileManager.default
        let storeURLs = [
            modelConfiguration.url,
            legacyDefaultStoreURL(),
        ]

        for baseURL in storeURLs {
            let paths = [
                baseURL.path,
                baseURL.path + "-shm",
                baseURL.path + "-wal",
            ]
            for path in paths where fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
        }
    }

    private static func legacyDefaultStoreURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("default.store")
    }
}
