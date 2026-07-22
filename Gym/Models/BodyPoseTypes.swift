import Foundation
import CoreGraphics

enum CameraFacing: String, Codable, CaseIterable, Identifiable {
    case front = "Frontale"
    case back = "Posteriore"

    var id: String { rawValue }

    var avPosition: String {
        switch self {
        case .front: "front"
        case .back: "back"
        }
    }
}

enum AnalysisReliability: String, Codable, CaseIterable {
    case high = "Alta"
    case medium = "Media"
    case low = "Bassa"

    var icon: String {
        switch self {
        case .high: "checkmark.shield.fill"
        case .medium: "exclamationmark.shield.fill"
        case .low: "xmark.shield.fill"
        }
    }

    var colorName: String {
        switch self {
        case .high: "green"
        case .medium: "orange"
        case .low: "red"
        }
    }
}

struct LandmarkPoint: Codable, Hashable, Identifiable {
    var id: String { joint }
    let joint: String
    let x: Double
    let y: Double
    let confidence: Float

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

struct BodyPoseSnapshot: Codable {
    let landmarks: [LandmarkPoint]
    let capturedAt: Date

    func point(for joint: String) -> LandmarkPoint? {
        landmarks.first { $0.joint == joint }
    }

    func cgPoint(for joint: String) -> CGPoint? {
        point(for: joint)?.cgPoint
    }

    static let requiredJoints = [
        "left_shoulder", "right_shoulder",
        "left_hip", "right_hip",
        "left_knee", "right_knee",
        "neck"
    ]

    var hasRequiredJoints: Bool {
        Self.requiredJoints.allSatisfy { point(for: $0) != nil }
    }

    var averageConfidence: Float {
        guard !landmarks.isEmpty else { return 0 }
        return landmarks.map(\.confidence).reduce(0, +) / Float(landmarks.count)
    }
}

struct BodyMetrics: Codable, Equatable {
    var shoulderWidth: Double
    var hipWidth: Double
    var shoulderToHipRatio: Double
    var shoulderAlignmentDegrees: Double
    var hipAlignmentDegrees: Double
    var torsoLength: Double
    var abdomenDefinition: Double
    var armsDefinition: Double
    var legsDefinition: Double
    var postureScore: Double

    func delta(from other: BodyMetrics) -> [String: Double] {
        var result: [String: Double] = [:]
        result["shoulderToHipRatio"] = shoulderToHipRatio - other.shoulderToHipRatio
        result["shoulderAlignmentDegrees"] = shoulderAlignmentDegrees - other.shoulderAlignmentDegrees
        result["hipAlignmentDegrees"] = hipAlignmentDegrees - other.hipAlignmentDegrees
        result["torsoLength"] = torsoLength - other.torsoLength
        result["abdomenDefinition"] = abdomenDefinition - other.abdomenDefinition
        result["armsDefinition"] = armsDefinition - other.armsDefinition
        result["legsDefinition"] = legsDefinition - other.legsDefinition
        result["postureScore"] = postureScore - other.postureScore
        return result
    }
}

struct AIAnalysisResult: Codable {
    let reliability: AnalysisReliability
    let summary: String
    let observedChanges: [String]
    let localizedChanges: [String]
    let suggestions: [String]
    let comparabilityNote: String
}

/// Posizioni guida normalizzate (0–1) per posa frontale standard
enum PoseGuideTemplate {
    static let joints: [String: CGPoint] = [
        "neck": CGPoint(x: 0.50, y: 0.14),
        "left_shoulder": CGPoint(x: 0.34, y: 0.24),
        "right_shoulder": CGPoint(x: 0.66, y: 0.24),
        "left_hip": CGPoint(x: 0.40, y: 0.50),
        "right_hip": CGPoint(x: 0.60, y: 0.50),
        "left_knee": CGPoint(x: 0.42, y: 0.72),
        "right_knee": CGPoint(x: 0.58, y: 0.72),
        "left_ankle": CGPoint(x: 0.43, y: 0.93),
        "right_ankle": CGPoint(x: 0.57, y: 0.93),
    ]

    static let connections: [(String, String)] = [
        ("neck", "left_shoulder"),
        ("neck", "right_shoulder"),
        ("left_shoulder", "right_shoulder"),
        ("left_shoulder", "left_hip"),
        ("right_shoulder", "right_hip"),
        ("left_hip", "right_hip"),
        ("left_hip", "left_knee"),
        ("right_hip", "right_knee"),
        ("left_knee", "left_ankle"),
        ("right_knee", "right_ankle"),
    ]

    static let alignmentTolerance: CGFloat = 0.08
    static let minimumAlignmentScore: Double = 0.72
    static let minimumComparabilityScore: Double = 0.65
}

enum BodyPoseCoding {
    static func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }

    static func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
