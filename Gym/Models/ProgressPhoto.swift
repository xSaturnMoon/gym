import Foundation
import SwiftData

@Model
final class ProgressAnalysisReport {
    var generatedAt: Date
    var reliabilityRaw: String
    var summaryText: String
    var observedChangesJSON: String
    var localizedChangesJSON: String
    var suggestionsJSON: String
    var comparabilityNote: String
    var wasSentToAPI: Bool

    @Relationship(inverse: \ProgressPhoto.analysisReport) var photo: ProgressPhoto?

    var reliability: AnalysisReliability {
        get { AnalysisReliability(rawValue: reliabilityRaw) ?? .medium }
        set { reliabilityRaw = newValue.rawValue }
    }

    var observedChanges: [String] {
        get { BodyPoseCoding.decode([String].self, from: observedChangesJSON) ?? [] }
        set { observedChangesJSON = BodyPoseCoding.encode(newValue) }
    }

    var localizedChanges: [String] {
        get { BodyPoseCoding.decode([String].self, from: localizedChangesJSON) ?? [] }
        set { localizedChangesJSON = BodyPoseCoding.encode(newValue) }
    }

    var suggestions: [String] {
        get { BodyPoseCoding.decode([String].self, from: suggestionsJSON) ?? [] }
        set { suggestionsJSON = BodyPoseCoding.encode(newValue) }
    }

    init(
        generatedAt: Date = .now,
        reliability: AnalysisReliability = .medium,
        summaryText: String = "",
        observedChanges: [String] = [],
        localizedChanges: [String] = [],
        suggestions: [String] = [],
        comparabilityNote: String = "",
        wasSentToAPI: Bool = false
    ) {
        self.generatedAt = generatedAt
        self.reliabilityRaw = reliability.rawValue
        self.summaryText = summaryText
        self.observedChangesJSON = BodyPoseCoding.encode(observedChanges)
        self.localizedChangesJSON = BodyPoseCoding.encode(localizedChanges)
        self.suggestionsJSON = BodyPoseCoding.encode(suggestions)
        self.comparabilityNote = comparabilityNote
        self.wasSentToAPI = wasSentToAPI
    }

    convenience init(from result: AIAnalysisResult, wasSentToAPI: Bool) {
        self.init(
            reliability: result.reliability,
            summaryText: result.summary,
            observedChanges: result.observedChanges,
            localizedChanges: result.localizedChanges,
            suggestions: result.suggestions,
            comparabilityNote: result.comparabilityNote,
            wasSentToAPI: wasSentToAPI
        )
    }
}

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: String
    var capturedAt: Date
    var imageData: Data
    var normalizedImageData: Data?
    var landmarksJSON: String
    var metricsJSON: String
    var cameraTypeRaw: String
    var alignmentScore: Double
    var comparabilityScore: Double
    var isBaseline: Bool
    var notes: String?

    @Relationship(deleteRule: .cascade) var analysisReport: ProgressAnalysisReport?

    var cameraFacing: CameraFacing {
        get { CameraFacing(rawValue: cameraTypeRaw) ?? .front }
        set { cameraTypeRaw = newValue.rawValue }
    }

    var poseSnapshot: BodyPoseSnapshot? {
        BodyPoseCoding.decode(BodyPoseSnapshot.self, from: landmarksJSON)
    }

    var metrics: BodyMetrics? {
        BodyPoseCoding.decode(BodyMetrics.self, from: metricsJSON)
    }

    var displayImageData: Data {
        normalizedImageData ?? imageData
    }

    init(
        id: String = UUID().uuidString,
        capturedAt: Date = .now,
        imageData: Data,
        normalizedImageData: Data? = nil,
        poseSnapshot: BodyPoseSnapshot,
        metrics: BodyMetrics,
        cameraFacing: CameraFacing,
        alignmentScore: Double,
        comparabilityScore: Double,
        isBaseline: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.imageData = imageData
        self.normalizedImageData = normalizedImageData
        self.landmarksJSON = BodyPoseCoding.encode(poseSnapshot)
        self.metricsJSON = BodyPoseCoding.encode(metrics)
        self.cameraTypeRaw = cameraFacing.rawValue
        self.alignmentScore = alignmentScore
        self.comparabilityScore = comparabilityScore
        self.isBaseline = isBaseline
        self.notes = notes
    }
}

@Model
final class ProgressPhotoSettings {
    @Attribute(.unique) var id: String
    var preferredCameraRaw: String
    var aiAnalysisEnabled: Bool
    var suggestedCaptureHour: Int
    var onboardingCompleted: Bool

    var preferredCamera: CameraFacing {
        get { CameraFacing(rawValue: preferredCameraRaw) ?? .front }
        set { preferredCameraRaw = newValue.rawValue }
    }

    init(
        id: String = "default",
        preferredCamera: CameraFacing = .front,
        aiAnalysisEnabled: Bool = true,
        suggestedCaptureHour: Int = 8,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.preferredCameraRaw = preferredCamera.rawValue
        self.aiAnalysisEnabled = aiAnalysisEnabled
        self.suggestedCaptureHour = suggestedCaptureHour
        self.onboardingCompleted = onboardingCompleted
    }
}
