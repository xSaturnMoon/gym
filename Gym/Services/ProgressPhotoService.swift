import Foundation
import SwiftData
import UIKit

@MainActor
final class ProgressPhotoService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func settings() -> ProgressPhotoSettings {
        let descriptor = FetchDescriptor<ProgressPhotoSettings>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let settings = ProgressPhotoSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        return settings
    }

    func allPhotos() -> [ProgressPhoto] {
        let descriptor = FetchDescriptor<ProgressPhoto>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func baseline() -> ProgressPhoto? {
        allPhotos().first { $0.isBaseline }
    }

    func previousPhoto(before date: Date) -> ProgressPhoto? {
        allPhotos().first { $0.capturedAt < date }
    }

    func savePhoto(
        image: UIImage,
        snapshot: BodyPoseSnapshot,
        camera: CameraFacing,
        alignmentScore: Double,
        runAIAnalysis: Bool
    ) async throws -> ProgressPhoto {
        guard alignmentScore >= PoseGuideTemplate.minimumAlignmentScore else {
            throw SaveError.poorAlignment
        }

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw SaveError.encodingFailed
        }

        let metrics = ProgressMetricsService.calculate(from: snapshot, image: image)
        let existingBaseline = baseline()
        let isBaseline = existingBaseline == nil

        var normalizedData: Data?
        var normalizedSnapshot = snapshot
        var comparabilityScore = 1.0

        if let baseline = existingBaseline,
           let refSnapshot = baseline.poseSnapshot,
           let result = PhotoNormalizationService.normalize(
               image: image,
               snapshot: snapshot,
               reference: refSnapshot
           ) {
            normalizedData = result.normalizedImage.jpegData(compressionQuality: 0.85)
            normalizedSnapshot = result.normalizedSnapshot
            comparabilityScore = result.comparabilityScore

            guard result.isComparable else {
                throw SaveError.notComparable
            }
        }

        let photo = ProgressPhoto(
            imageData: imageData,
            normalizedImageData: normalizedData,
            poseSnapshot: normalizedSnapshot,
            metrics: metrics,
            cameraFacing: camera,
            alignmentScore: alignmentScore,
            comparabilityScore: comparabilityScore,
            isBaseline: isBaseline
        )

        if isBaseline {
            photo.analysisReport = ProgressAnalysisReport(
                from: GeminiAnalysisService.localFallbackAnalysis(
                    metrics: metrics,
                    baseline: nil,
                    comparabilityScore: 1.0,
                    geometricChanges: ProgressMetricsService.descriptiveBaselineReport(metrics: metrics)
                ),
                wasSentToAPI: false
            )
        }

        modelContext.insert(photo)

        if !isBaseline, runAIAnalysis {
            try await generateAnalysis(for: photo)
        } else if !isBaseline {
            let baselineMetrics = existingBaseline?.metrics
            let geometric = baselineMetrics.map {
                ProgressMetricsService.metricChanges(current: metrics, baseline: $0)
            } ?? []
            photo.analysisReport = ProgressAnalysisReport(
                from: GeminiAnalysisService.localFallbackAnalysis(
                    metrics: metrics,
                    baseline: baselineMetrics,
                    comparabilityScore: comparabilityScore,
                    geometricChanges: geometric
                ),
                wasSentToAPI: false
            )
        }

        try modelContext.save()
        return photo
    }

    func generateAnalysis(for photo: ProgressPhoto) async throws {
        let settings = settings()
        let baseline = baseline()
        let previous = previousPhoto(before: photo.capturedAt)
        guard let metrics = photo.metrics else { return }

        let geometricChanges: [String] = if let baselineMetrics = baseline?.metrics {
            ProgressMetricsService.metricChanges(current: metrics, baseline: baselineMetrics)
        } else {
            []
        }

        let rawImageData = photo.normalizedImageData ?? photo.imageData
        let imageData: Data
        if settings.censorIntimateAreas,
           let image = UIImage(data: rawImageData),
           let snapshot = photo.poseSnapshot,
           let censoredData = IntimateAreaCensorshipService.censoredJPEGData(from: image, snapshot: snapshot) {
            imageData = censoredData
        } else {
            imageData = rawImageData
        }

        let result: AIAnalysisResult
        var sentToAPI = false

        if settings.aiAnalysisEnabled,
           let apiKey = KeychainHelper.loadGeminiAPIKey(),
           !apiKey.isEmpty {
            let planName = activePlanName()
            result = try await GeminiAnalysisService.analyze(
                normalizedImageData: imageData,
                metrics: metrics,
                baselineMetrics: baseline?.metrics,
                previousMetrics: previous?.metrics,
                comparabilityScore: photo.comparabilityScore,
                alignmentScore: photo.alignmentScore,
                activePlanName: planName,
                apiKey: apiKey
            )
            sentToAPI = true
        } else {
            result = GeminiAnalysisService.localFallbackAnalysis(
                metrics: metrics,
                baseline: baseline?.metrics,
                comparabilityScore: photo.comparabilityScore,
                geometricChanges: geometricChanges
            )
        }

        if let existing = photo.analysisReport {
            modelContext.delete(existing)
        }
        photo.analysisReport = ProgressAnalysisReport(from: result, wasSentToAPI: sentToAPI)
        try modelContext.save()
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        let wasBaseline = photo.isBaseline
        modelContext.delete(photo)
        try? modelContext.save()

        if wasBaseline {
            if let next = allPhotos().sorted(by: { $0.capturedAt < $1.capturedAt }).first {
                next.isBaseline = true
                try? modelContext.save()
            }
        }
    }

    func deleteAllPhotos() {
        let photos = allPhotos()
        photos.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }

    private func activePlanName() -> String? {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(profileDescriptor).first,
              let planID = profile.activePlanID else { return nil }
        let planDescriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.id == planID }
        )
        return try? modelContext.fetch(planDescriptor).first?.name
    }

    enum SaveError: LocalizedError {
        case poorAlignment
        case notComparable
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .poorAlignment:
                "Allineati alla sagoma guida prima di scattare. La posa non è abbastanza precisa."
            case .notComparable:
                "Foto non comparabile in modo affidabile. Ripeti lo scatto allineandoti meglio alla guida."
            case .encodingFailed:
                "Impossibile salvare l'immagine."
            }
        }
    }
}
