import Foundation
import SwiftData

@MainActor
final class DataController {
    let container: ModelContainer

    static let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Exercise.self, WorkoutPlan.self, PlannedDay.self, PlannedExercise.self,
                 WorkoutSession.self, CompletedExercise.self, CompletedSet.self, UserProfile.self,
            configurations: config
        )
        let context = container.mainContext
        ExerciseLibrary.seed(into: context)
        WorkoutPlansSeed.seed(into: context)
        context.insert(UserProfile())
        return container
    }()

    init() {
        do {
            container = try ModelContainer(
                for: Exercise.self, WorkoutPlan.self, PlannedDay.self, PlannedExercise.self,
                     WorkoutSession.self, CompletedExercise.self, CompletedSet.self, UserProfile.self
            )
        } catch {
            fatalError("Impossibile inizializzare SwiftData: \(error)")
        }
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

        try? context.save()
    }
}
