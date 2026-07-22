import Foundation
import SwiftData

@MainActor
enum WorkoutPlansSeed {
    static func seed(into context: ModelContext) {
        let plans = [
            makeFullBody3Beginner(),
            makeFullBody3Intermediate(),
            makeFullBody3Advanced(),
            makePushPullCore(),
        ]
        plans.forEach { context.insert($0) }
    }

    // MARK: - Full Body Principiante (3 giorni/settimana)

    static func makeFullBody3Beginner() -> WorkoutPlan {
        let plan = WorkoutPlan(
            id: "plan-fullbody3-beginner",
            name: "Full Body Principiante",
            planType: .fullBody3,
            level: .beginner,
            isActive: true
        )

        let weekDays: [(name: String, type: DayType, exercises: [(String, Int, Int?, Int?)])] = [
            ("Lunedì — Forza base", .workout, [
                ("bodyweight-squat", 3, 12, nil),
                ("push-up", 3, 8, nil),
                ("glute-bridge", 3, 15, nil),
                ("plank", 3, nil, 25),
                ("dead-bug", 3, 10, nil),
            ]),
            ("Martedì — Recupero attivo", .activeRecovery, [
                ("cat-cow", 2, 10, nil),
                ("hip-flexor-stretch", 2, nil, 30),
                ("child-pose", 1, nil, 60),
                ("hamstring-stretch", 2, nil, 30),
            ]),
            ("Mercoledì — Riposo", .rest, []),
            ("Giovedì — Gambe e core", .workout, [
                ("reverse-lunge", 3, 10, nil),
                ("wall-sit", 3, nil, 25),
                ("glute-bridge", 3, 15, nil),
                ("side-plank", 2, nil, 20),
                ("calf-raise", 3, 20, nil),
            ]),
            ("Venerdì — Riposo", .rest, []),
            ("Sabato — Upper + cardio leggero", .workout, [
                ("incline-push-up", 3, 12, nil),
                ("tricep-dip-chair", 3, 10, nil),
                ("superman", 3, 12, nil),
                ("reverse-snow-angel", 3, 12, nil),
                ("jumping-jack", 2, nil, 30),
            ]),
            ("Domenica — Mobilità", .activeRecovery, [
                ("cat-cow", 2, 10, nil),
                ("thoracic-rotation", 2, 8, nil),
                ("hip-flexor-stretch", 2, nil, 30),
                ("child-pose", 1, nil, 60),
            ]),
        ]

        plan.days = weekDays.enumerated().map { index, day in
            makeDay(
                planID: plan.id,
                weekIndex: 0,
                orderIndex: index,
                dayOfWeek: index + 1,
                name: day.name,
                type: day.type,
                exercises: day.exercises
            )
        }
        return plan
    }

    // MARK: - Full Body Intermedio

    static func makeFullBody3Intermediate() -> WorkoutPlan {
        let plan = WorkoutPlan(
            id: "plan-fullbody3-intermediate",
            name: "Full Body Intermedio",
            planType: .fullBody3,
            level: .intermediate
        )

        let weekDays: [(String, DayType, [(String, Int, Int?, Int?)])] = [
            ("Lunedì — Forza", .workout, [
                ("bodyweight-squat", 4, 15, nil),
                ("push-up", 4, 12, nil),
                ("reverse-lunge", 3, 12, nil),
                ("plank", 3, nil, 40),
                ("mountain-climber", 3, nil, 30),
            ]),
            ("Martedì — Mobilità", .activeRecovery, [
                ("worlds-greatest-stretch", 2, 6, nil),
                ("hip-flexor-stretch", 2, nil, 30),
                ("hamstring-stretch", 2, nil, 30),
            ]),
            ("Mercoledì — Riposo", .rest, []),
            ("Giovedì — Gambe e schiena", .workout, [
                ("bulgarian-split-squat", 3, 10, nil),
                ("glute-bridge", 4, 15, nil),
                ("inverted-row-table", 3, 10, nil),
                ("good-morning-bodyweight", 3, 12, nil),
                ("side-plank", 3, nil, 30),
            ]),
            ("Venerdì — Riposo", .rest, []),
            ("Sabato — Upper + HIIT", .workout, [
                ("pike-push-up", 3, 8, nil),
                ("diamond-push-up", 3, 8, nil),
                ("shoulder-tap", 3, 20, nil),
                ("jump-squat", 3, 12, nil),
                ("high-knees", 3, nil, 30),
            ]),
            ("Domenica — Recupero", .activeRecovery, [
                ("cat-cow", 2, 10, nil),
                ("child-pose", 1, nil, 90),
                ("thoracic-rotation", 2, 8, nil),
            ]),
        ]

        plan.days = weekDays.enumerated().map { index, day in
            makeDay(
                planID: plan.id,
                weekIndex: 0,
                orderIndex: index,
                dayOfWeek: index + 1,
                name: day.0,
                type: day.1,
                exercises: day.2
            )
        }
        return plan
    }

    // MARK: - Full Body Avanzato

    static func makeFullBody3Advanced() -> WorkoutPlan {
        let plan = WorkoutPlan(
            id: "plan-fullbody4-advanced",
            name: "Full Body Avanzato",
            planType: .fullBody4,
            level: .advanced
        )

        let weekDays: [(String, DayType, [(String, Int, Int?, Int?)])] = [
            ("Lunedì — Forza esplosiva", .workout, [
                ("jump-squat", 4, 12, nil),
                ("push-up", 4, 15, nil),
                ("bulgarian-split-squat", 3, 12, nil),
                ("hollow-hold", 3, nil, 30),
                ("burpee", 3, 8, nil),
            ]),
            ("Martedì — Mobilità attiva", .activeRecovery, [
                ("worlds-greatest-stretch", 3, 6, nil),
                ("hip-flexor-stretch", 2, nil, 40),
                ("thoracic-rotation", 2, 10, nil),
            ]),
            ("Mercoledì — Push intenso", .workout, [
                ("pike-push-up", 4, 10, nil),
                ("diamond-push-up", 3, 10, nil),
                ("tricep-dip-chair", 4, 15, nil),
                ("shoulder-tap", 3, 24, nil),
                ("plank", 3, nil, 45),
            ]),
            ("Giovedì — Riposo", .rest, []),
            ("Venerdì — Pull e gambe", .workout, [
                ("inverted-row-table", 4, 12, nil),
                ("superman", 3, 15, nil),
                ("good-morning-bodyweight", 3, 15, nil),
                ("step-up", 3, 12, nil),
                ("mountain-climber", 4, nil, 40),
            ]),
            ("Sabato — HIIT", .workout, [
                ("burpee", 4, 10, nil),
                ("skater-hop", 3, nil, 40),
                ("jump-squat", 3, 15, nil),
                ("high-knees", 3, nil, 40),
                ("jumping-jack", 3, nil, 40),
            ]),
            ("Domenica — Stretching", .activeRecovery, [
                ("hamstring-stretch", 2, nil, 40),
                ("hip-flexor-stretch", 2, nil, 40),
                ("child-pose", 1, nil, 90),
            ]),
        ]

        plan.days = weekDays.enumerated().map { index, day in
            makeDay(
                planID: plan.id,
                weekIndex: 0,
                orderIndex: index,
                dayOfWeek: index + 1,
                name: day.0,
                type: day.1,
                exercises: day.2
            )
        }
        return plan
    }

    // MARK: - Push/Pull/Core/Cardio

    static func makePushPullCore() -> WorkoutPlan {
        let plan = WorkoutPlan(
            id: "plan-pushpullcore",
            name: "Push / Pull / Core / Cardio",
            planType: .pushPullCore,
            level: .intermediate
        )

        let weekDays: [(String, DayType, [(String, Int, Int?, Int?)])] = [
            ("Lunedì — Push", .workout, [
                ("push-up", 4, 12, nil),
                ("pike-push-up", 3, 10, nil),
                ("diamond-push-up", 3, 10, nil),
                ("tricep-dip-chair", 3, 12, nil),
                ("shoulder-tap", 3, 20, nil),
            ]),
            ("Martedì — Pull", .workout, [
                ("inverted-row-table", 4, 12, nil),
                ("superman", 3, 15, nil),
                ("reverse-snow-angel", 3, 15, nil),
                ("prone-y-raise", 3, 12, nil),
                ("good-morning-bodyweight", 3, 12, nil),
            ]),
            ("Mercoledì — Core", .workout, [
                ("plank", 3, nil, 45),
                ("side-plank", 3, nil, 30),
                ("hollow-hold", 3, nil, 25),
                ("dead-bug", 3, 12, nil),
                ("bicycle-crunch", 3, 20, nil),
            ]),
            ("Giovedì — Riposo", .rest, []),
            ("Venerdì — Cardio HIIT", .workout, [
                ("jumping-jack", 3, nil, 40),
                ("high-knees", 3, nil, 40),
                ("skater-hop", 3, nil, 30),
                ("mountain-climber", 3, nil, 40),
                ("jump-squat", 3, 12, nil),
            ]),
            ("Sabato — Gambe", .workout, [
                ("bodyweight-squat", 4, 15, nil),
                ("reverse-lunge", 3, 12, nil),
                ("bulgarian-split-squat", 3, 10, nil),
                ("glute-bridge", 3, 15, nil),
                ("calf-raise", 3, 20, nil),
            ]),
            ("Domenica — Mobilità", .activeRecovery, [
                ("cat-cow", 2, 10, nil),
                ("worlds-greatest-stretch", 2, 6, nil),
                ("child-pose", 1, nil, 90),
            ]),
        ]

        plan.days = weekDays.enumerated().map { index, day in
            makeDay(
                planID: plan.id,
                weekIndex: 0,
                orderIndex: index,
                dayOfWeek: index + 1,
                name: day.0,
                type: day.1,
                exercises: day.2
            )
        }
        return plan
    }

    private static func makeDay(
        planID: String,
        weekIndex: Int,
        orderIndex: Int,
        dayOfWeek: Int,
        name: String,
        type: DayType,
        exercises: [(String, Int, Int?, Int?)]
    ) -> PlannedDay {
        let day = PlannedDay(
            id: "\(planID)-w\(weekIndex)-d\(orderIndex)",
            name: name,
            dayType: type,
            weekIndex: weekIndex,
            dayOfWeek: dayOfWeek,
            orderIndex: orderIndex
        )

        day.exercises = exercises.enumerated().map { idx, entry in
            let (exerciseID, sets, reps, duration) = entry
            let libraryExercise = ExerciseLibrary.exercise(byID: exerciseID)
            return PlannedExercise(
                exerciseID: exerciseID,
                orderIndex: idx,
                sets: sets,
                reps: reps,
                durationSeconds: duration,
                restSeconds: libraryExercise?.defaultRestSeconds ?? 60
            )
        }
        return day
    }
}
