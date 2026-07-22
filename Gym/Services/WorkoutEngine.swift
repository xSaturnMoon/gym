import Foundation
import SwiftData

@MainActor
final class WorkoutEngine {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func activePlan() -> WorkoutPlan? {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(profileDescriptor).first,
              let planID = profile.activePlanID else { return nil }

        let planDescriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.id == planID }
        )
        return try? modelContext.fetch(planDescriptor).first
    }

    func todayPlannedDay() -> PlannedDay? {
        guard let plan = activePlan() else { return nil }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        // Calendar weekday: 1=Sunday, convert to our 1=Monday
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1

        return plan.sortedDays.first { day in
            day.dayOfWeek == adjustedWeekday && !day.isSkipped
        }
    }

    func exercise(for planned: PlannedExercise) -> Exercise? {
        let id = planned.exerciseID
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func allExercises() -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func exercises(for category: ExerciseCategory) -> [Exercise] {
        let raw = category.rawValue
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.categoryRaw == raw },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func completeWorkout(
        plannedDay: PlannedDay,
        durationMinutes: Int,
        notes: String?,
        perceivedDifficulty: Int?
    ) {
        let session = WorkoutSession(
            plannedDayID: plannedDay.id,
            workoutName: plannedDay.name,
            durationMinutes: durationMinutes,
            isCompleted: true,
            notes: notes,
            perceivedDifficulty: perceivedDifficulty
        )

        for planned in plannedDay.sortedExercises {
            let exercise = self.exercise(for: planned)
            let completed = CompletedExercise(
                exerciseID: planned.exerciseID,
                exerciseName: exercise?.name ?? planned.exerciseID,
                orderIndex: planned.orderIndex
            )
            completed.sets = (1...planned.sets).map { setNum in
                CompletedSet(
                    setNumber: setNum,
                    reps: planned.reps,
                    durationSeconds: planned.durationSeconds,
                    completed: true
                )
            }
            session.exercises.append(completed)
        }

        modelContext.insert(session)
        updateStreak()
        try? modelContext.save()
    }

    func skipDay(_ day: PlannedDay) {
        day.isSkipped = true
        try? modelContext.save()
    }

    func unskipDay(_ day: PlannedDay) {
        day.isSkipped = false
        try? modelContext.save()
    }

    func setActivePlan(_ plan: WorkoutPlan) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
        let profile = profiles.first ?? UserProfile()
        if profiles.isEmpty { modelContext.insert(profile) }

        let allPlans = FetchDescriptor<WorkoutPlan>()
        if let plans = try? modelContext.fetch(allPlans) {
            plans.forEach { $0.isActive = $0.id == plan.id }
        }
        profile.activePlanID = plan.id
        plan.isActive = true
        try? modelContext.save()
    }

    func allSessions() -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func completedSessions() -> [WorkoutSession] {
        allSessions().filter(\.isCompleted)
    }

    func sessionsInRange(from start: Date, to end: Date) -> [WorkoutSession] {
        completedSessions().filter { $0.date >= start && $0.date <= end }
    }

    private func updateStreak() {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(profileDescriptor).first else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let lastDate = profile.lastWorkoutDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 0 {
                // Already worked out today
            } else if daysBetween == 1 {
                profile.currentStreak += 1
            } else {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        profile.lastWorkoutDate = .now
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
    }

    func resetAllData() {
        try? modelContext.delete(model: Exercise.self)
        try? modelContext.delete(model: WorkoutPlan.self)
        try? modelContext.delete(model: PlannedDay.self)
        try? modelContext.delete(model: PlannedExercise.self)
        try? modelContext.delete(model: WorkoutSession.self)
        try? modelContext.delete(model: CompletedExercise.self)
        try? modelContext.delete(model: CompletedSet.self)
        try? modelContext.delete(model: UserProfile.self)

        ExerciseLibrary.seed(into: modelContext)
        WorkoutPlansSeed.seed(into: modelContext)
        let profile = UserProfile()
        profile.activePlanID = "plan-fullbody3-beginner"
        modelContext.insert(profile)
        try? modelContext.save()
    }
}
