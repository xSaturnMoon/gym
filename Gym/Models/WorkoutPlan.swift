import Foundation
import SwiftData

@Model
final class PlannedExercise {
    var exerciseID: String
    var orderIndex: Int
    var sets: Int
    var reps: Int?
    var durationSeconds: Int?
    var restSeconds: Int
    var notes: String?

    @Relationship(inverse: \PlannedDay.exercises) var day: PlannedDay?

    init(
        exerciseID: String,
        orderIndex: Int,
        sets: Int,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        restSeconds: Int = 60,
        notes: String? = nil
    ) {
        self.exerciseID = exerciseID
        self.orderIndex = orderIndex
        self.sets = sets
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

@Model
final class PlannedDay {
    @Attribute(.unique) var id: String
    var name: String
    var dayTypeRaw: String
    var weekIndex: Int
    var dayOfWeek: Int
    var orderIndex: Int
    var isSkipped: Bool
    var scheduledDate: Date?

    @Relationship(deleteRule: .cascade) var exercises: [PlannedExercise]

    @Relationship(inverse: \WorkoutPlan.days) var plan: WorkoutPlan?

    var dayType: DayType {
        get { DayType(rawValue: dayTypeRaw) ?? .workout }
        set { dayTypeRaw = newValue.rawValue }
    }

    init(
        id: String,
        name: String,
        dayType: DayType,
        weekIndex: Int,
        dayOfWeek: Int,
        orderIndex: Int,
        exercises: [PlannedExercise] = [],
        isSkipped: Bool = false,
        scheduledDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dayTypeRaw = dayType.rawValue
        self.weekIndex = weekIndex
        self.dayOfWeek = dayOfWeek
        self.orderIndex = orderIndex
        self.exercises = exercises
        self.isSkipped = isSkipped
        self.scheduledDate = scheduledDate
    }

    var sortedExercises: [PlannedExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class WorkoutPlan {
    @Attribute(.unique) var id: String
    var name: String
    var planTypeRaw: String
    var levelRaw: String
    var isActive: Bool
    var startDate: Date
    var currentWeekIndex: Int

    @Relationship(deleteRule: .cascade) var days: [PlannedDay]

    var planType: PlanType {
        get { PlanType(rawValue: planTypeRaw) ?? .fullBody3 }
        set { planTypeRaw = newValue.rawValue }
    }

    var level: DifficultyLevel {
        get { DifficultyLevel(rawValue: levelRaw) ?? .beginner }
        set { levelRaw = newValue.rawValue }
    }

    init(
        id: String,
        name: String,
        planType: PlanType,
        level: DifficultyLevel,
        isActive: Bool = false,
        startDate: Date = .now,
        currentWeekIndex: Int = 0,
        days: [PlannedDay] = []
    ) {
        self.id = id
        self.name = name
        self.planTypeRaw = planType.rawValue
        self.levelRaw = level.rawValue
        self.isActive = isActive
        self.startDate = startDate
        self.currentWeekIndex = currentWeekIndex
        self.days = days
    }

    var sortedDays: [PlannedDay] {
        days.sorted {
            if $0.weekIndex != $1.weekIndex { return $0.weekIndex < $1.weekIndex }
            return $0.orderIndex < $1.orderIndex
        }
    }
}
