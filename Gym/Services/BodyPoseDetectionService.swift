import Vision
import UIKit
import CoreGraphics

enum BodyPoseDetectionService {
    private static let jointMap: [VNHumanBodyPoseObservation.JointName: String] = [
        .neck: "neck",
        .leftShoulder: "left_shoulder",
        .rightShoulder: "right_shoulder",
        .leftHip: "left_hip",
        .rightHip: "right_hip",
        .leftKnee: "left_knee",
        .rightKnee: "right_knee",
        .leftAnkle: "left_ankle",
        .rightAnkle: "right_ankle",
        .leftElbow: "left_elbow",
        .rightElbow: "right_elbow",
        .leftWrist: "left_wrist",
        .rightWrist: "right_wrist",
        .root: "root",
    ]

    static func detectPose(in image: UIImage) async throws -> BodyPoseSnapshot {
        guard let cgImage = image.cgImage else {
            throw PoseDetectionError.invalidImage
        }
        return try await detectPose(in: cgImage, orientation: cgImageOrientation(from: image))
    }

    static func detectPose(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) throws -> BodyPoseSnapshot {
        var detectedSnapshot: BodyPoseSnapshot?
        var detectionError: Error?

        let request = VNDetectHumanBodyPoseRequest { request, error in
            if let error {
                detectionError = error
                return
            }
            guard let observation = (request.results as? [VNHumanBodyPoseObservation])?.first else {
                detectionError = PoseDetectionError.noBodyDetected
                return
            }
            detectedSnapshot = snapshot(from: observation)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        try handler.perform([request])

        if let detectionError {
            throw detectionError
        }
        guard let detectedSnapshot else {
            throw PoseDetectionError.noBodyDetected
        }
        return detectedSnapshot
    }

    static func detectPose(in cgImage: CGImage, orientation: CGImagePropertyOrientation = .up) async throws -> BodyPoseSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observation = (request.results as? [VNHumanBodyPoseObservation])?.first else {
                    continuation.resume(throwing: PoseDetectionError.noBodyDetected)
                    return
                }
                continuation.resume(returning: snapshot(from: observation))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func alignmentScore(for snapshot: BodyPoseSnapshot) -> Double {
        var scores: [Double] = []
        let tolerance = Double(PoseGuideTemplate.alignmentTolerance)

        for (joint, target) in PoseGuideTemplate.joints {
            guard let detected = snapshot.point(for: joint), detected.confidence > 0.3 else {
                scores.append(0)
                continue
            }
            let dx = Double(detected.x) - Double(target.x)
            let dy = Double(detected.y) - Double(target.y)
            let distance = sqrt(dx * dx + dy * dy)
            let score = max(0, 1 - distance / tolerance)
            scores.append(score * Double(detected.confidence))
        }

        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    static func isAlignedForCapture(_ snapshot: BodyPoseSnapshot) -> Bool {
        snapshot.hasRequiredJoints && alignmentScore(for: snapshot) >= PoseGuideTemplate.minimumAlignmentScore
    }

    private static func snapshot(from observation: VNHumanBodyPoseObservation) -> BodyPoseSnapshot {
        var landmarks: [LandmarkPoint] = []
        for (vnJoint, name) in jointMap {
            if let point = try? observation.recognizedPoint(vnJoint), point.confidence > 0.1 {
                landmarks.append(LandmarkPoint(
                    joint: name,
                    x: Double(point.location.x),
                    y: Double(1 - point.location.y),
                    confidence: point.confidence
                ))
            }
        }
        return BodyPoseSnapshot(landmarks: landmarks, capturedAt: .now)
    }

    private static func cgImageOrientation(from image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }

    enum PoseDetectionError: LocalizedError {
        case invalidImage
        case noBodyDetected

        var errorDescription: String? {
            switch self {
            case .invalidImage: "Immagine non valida."
            case .noBodyDetected: "Nessun corpo rilevato. Posizionati davanti alla camera."
            }
        }
    }
}
