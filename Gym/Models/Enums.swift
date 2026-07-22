import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case chestShouldersArms = "Petto/Spalle/Braccia"
    case legsGlutes = "Gambe/Glutei"
    case core = "Core/Addome"
    case back = "Schiena"
    case cardioHIIT = "Cardio/HIIT"
    case mobility = "Mobilità/Stretching"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chestShouldersArms: "figure.arms.open"
        case .legsGlutes: "figure.walk"
        case .core: "figure.core.training"
        case .back: "figure.rowing"
        case .cardioHIIT: "heart.fill"
        case .mobility: "figure.flexibility"
        }
    }

    var suggestedChannels: String {
        switch self {
        case .chestShouldersArms:
            "Hybrid Calisthenics, Calisthenicmovement, Athlean-X"
        case .legsGlutes:
            "Squat University, Bob & Brad, Hybrid Calisthenics"
        case .core:
            "Athlean-X, Calisthenicmovement, MadFit"
        case .back:
            "Bob & Brad, Athlean-X, FitnessFAQs"
        case .cardioHIIT:
            "MadFit, Pamela Reif, Nobadaddiction"
        case .mobility:
            "Bob & Brad, Squat University, Yoga With Adriene"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Principiante"
    case intermediate = "Intermedio"
    case advanced = "Avanzato"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        }
    }
}

enum WorkoutGoal: String, Codable, CaseIterable, Identifiable {
    case weightLoss = "Dimagrimento"
    case toning = "Tonificazione"
    case energy = "Energia e benessere"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weightLoss: "flame.fill"
        case .toning: "figure.strengthtraining.traditional"
        case .energy: "bolt.fill"
        }
    }
}

enum PlanType: String, Codable, CaseIterable, Identifiable {
    case fullBody3 = "Full Body 3 giorni"
    case fullBody4 = "Full Body 4 giorni"
    case pushPullCore = "Push/Pull/Core/Cardio"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .fullBody3:
            "Ideale per iniziare: corpo intero 3 volte a settimana con giorni di recupero."
        case .fullBody4:
            "Per chi ha già una base: 4 sessioni full body con maggiore volume."
        case .pushPullCore:
            "Split alternativo: spinta, tirata, core e cardio in giorni dedicati."
        }
    }
}

enum DayType: String, Codable {
    case workout = "Allenamento"
    case activeRecovery = "Recupero attivo"
    case rest = "Riposo"
}

enum ExerciseMetric: String, Codable {
    case reps = "Ripetizioni"
    case time = "Tempo"
    case distance = "Distanza"
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "kg"
    case lb = "lb"

    var id: String { rawValue }
}

enum LengthUnit: String, Codable, CaseIterable, Identifiable {
    case cm = "cm"
    case inches = "in"

    var id: String { rawValue }
}
