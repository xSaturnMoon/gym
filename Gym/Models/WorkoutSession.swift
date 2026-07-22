import Foundation
import SwiftData

@Model
final class CompletedSet {
    var setNumber: Int
    var reps: Int?
    var durationSeconds: Int?
    var completed: Bool

    @Relationship(inverse: \CompletedExercise.sets) var exercise: CompletedExercise?

    init(setNumber: Int, reps: Int? = nil, durationSeconds: Int? = nil, completed: Bool = false) {
        self.setNumber = setNumber
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.completed = completed
    }
}

@Model
final class CompletedExercise {
    var exerciseID: String
    var exerciseName: String
    var orderIndex: Int

    @Relationship(deleteRule: .cascade) var sets: [CompletedSet]

    @Relationship(inverse: \WorkoutSession.exercises) var session: WorkoutSession?

    init(exerciseID: String, exerciseName: String, orderIndex: Int, sets: [CompletedSet] = []) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.orderIndex = orderIndex
        self.sets = sets
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: String
    var date: Date
    var plannedDayID: String?
    var workoutName: String
    var durationMinutes: Int
    var isCompleted: Bool
    var notes: String?
    var perceivedDifficulty: Int?
    var caloriesEstimate: Int?

    @Relationship(deleteRule: .cascade) var exercises: [CompletedExercise]

    init(
        id: String = UUID().uuidString,
        date: Date = .now,
        plannedDayID: String? = nil,
        workoutName: String,
        durationMinutes: Int = 0,
        isCompleted: Bool = false,
        notes: String? = nil,
        perceivedDifficulty: Int? = nil,
        caloriesEstimate: Int? = nil,
        exercises: [CompletedExercise] = []
    ) {
        self.id = id
        self.date = date
        self.plannedDayID = plannedDayID
        self.workoutName = workoutName
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.notes = notes
        self.perceivedDifficulty = perceivedDifficulty
        self.caloriesEstimate = caloriesEstimate
        self.exercises = exercises
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var name: String
    var weight: Double?
    var goalRaw: String
    var weightUnitRaw: String
    var lengthUnitRaw: String
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?
    var activePlanID: String?

    var goal: WorkoutGoal {
        get { WorkoutGoal(rawValue: goalRaw) ?? .energy }
        set { goalRaw = newValue.rawValue }
    }

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    var lengthUnit: LengthUnit {
        get { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }
        set { lengthUnitRaw = newValue.rawValue }
    }

    init(
        id: String = "default",
        name: String = "",
        weight: Double? = nil,
        goal: WorkoutGoal = .energy,
        weightUnit: WeightUnit = .kg,
        lengthUnit: LengthUnit = .cm,
        remindersEnabled: Bool = false,
        reminderHour: Int = 8,
        reminderMinute: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastWorkoutDate: Date? = nil,
        activePlanID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.weight = weight
        self.goalRaw = goal.rawValue
        self.weightUnitRaw = weightUnit.rawValue
        self.lengthUnitRaw = lengthUnit.rawValue
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.activePlanID = activePlanID
    }
}
