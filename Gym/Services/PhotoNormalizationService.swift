import UIKit
import CoreGraphics

@MainActor
enum PhotoNormalizationService {
    struct NormalizationResult {
        let normalizedImage: UIImage
        let normalizedSnapshot: BodyPoseSnapshot
        let comparabilityScore: Double
        let isComparable: Bool
    }

    static func normalize(
        image: UIImage,
        snapshot: BodyPoseSnapshot,
        reference: BodyPoseSnapshot
    ) -> NormalizationResult? {
        guard let refShoulders = shoulderLine(reference),
              let curShoulders = shoulderLine(snapshot),
              let refHips = hipLine(reference),
              let curHips = hipLine(snapshot) else {
            return nil
        }

        let refCenter = midpoint(refShoulders.0, refHips.0)
        let curCenter = midpoint(curShoulders.0, curHips.0)

        let refAngle = angle(from: refShoulders.0, to: refShoulders.1)
        let curAngle = angle(from: curShoulders.0, to: curShoulders.1)
        let rotation = refAngle - curAngle

        let refTorso = distance(refShoulders.0, refHips.0)
        let curTorso = distance(curShoulders.0, curHips.0)
        guard curTorso > 0.01 else { return nil }
        let scale = refTorso / curTorso

        guard let normalizedImage = applyTransform(
            to: image,
            rotation: rotation,
            scale: scale,
            sourceCenter: curCenter,
            targetCenter: refCenter
        ) else { return nil }

        let transformedLandmarks = snapshot.landmarks.map { landmark in
            let transformed = transformPoint(
                landmark.cgPoint,
                rotation: rotation,
                scale: scale,
                sourceCenter: curCenter,
                targetCenter: refCenter
            )
            return LandmarkPoint(
                joint: landmark.joint,
                x: Double(transformed.x),
                y: Double(transformed.y),
                confidence: landmark.confidence
            )
        }

        let normalizedSnapshot = BodyPoseSnapshot(
            landmarks: transformedLandmarks,
            capturedAt: snapshot.capturedAt
        )

        let comparability = comparabilityScore(
            normalized: normalizedSnapshot,
            reference: reference
        )

        return NormalizationResult(
            normalizedImage: normalizedImage,
            normalizedSnapshot: normalizedSnapshot,
            comparabilityScore: comparability,
            isComparable: comparability >= PoseGuideTemplate.minimumComparabilityScore
        )
    }

    static func comparabilityScore(normalized: BodyPoseSnapshot, reference: BodyPoseSnapshot) -> Double {
        var scores: [Double] = []
        let tolerance = Double(PoseGuideTemplate.alignmentTolerance) * 1.5

        for (joint, target) in PoseGuideTemplate.joints {
            guard let detected = normalized.point(for: joint) else { continue }
            let dx = detected.x - Double(target.x)
            let dy = detected.y - Double(target.y)
            let distance = sqrt(dx * dx + dy * dy)
            let score = max(0, 1 - distance / tolerance)
            scores.append(score)
        }

        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private static func shoulderLine(_ snapshot: BodyPoseSnapshot) -> (CGPoint, CGPoint)? {
        guard let left = snapshot.cgPoint(for: "left_shoulder"),
              let right = snapshot.cgPoint(for: "right_shoulder") else { return nil }
        return (left, right)
    }

    private static func hipLine(_ snapshot: BodyPoseSnapshot) -> (CGPoint, CGPoint)? {
        guard let left = snapshot.cgPoint(for: "left_hip"),
              let right = snapshot.cgPoint(for: "right_hip") else { return nil }
        return (left, right)
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private static func angle(from a: CGPoint, to b: CGPoint) -> CGFloat {
        atan2(b.y - a.y, b.x - a.x)
    }

    private static func transformPoint(
        _ point: CGPoint,
        rotation: CGFloat,
        scale: CGFloat,
        sourceCenter: CGPoint,
        targetCenter: CGPoint
    ) -> CGPoint {
        var p = CGPoint(x: point.x - sourceCenter.x, y: point.y - sourceCenter.y)
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let rx = p.x * cosR - p.y * sinR
        let ry = p.x * sinR + p.y * cosR
        p = CGPoint(x: rx * scale, y: ry * scale)
        return CGPoint(x: p.x + targetCenter.x, y: p.y + targetCenter.y)
    }

    private static func applyTransform(
        to image: UIImage,
        rotation: CGFloat,
        scale: CGFloat,
        sourceCenter: CGPoint,
        targetCenter: CGPoint
    ) -> UIImage? {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            ctx.translateBy(x: targetCenter.x * size.width, y: targetCenter.y * size.height)
            ctx.rotate(by: rotation)
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -sourceCenter.x * size.width, y: -sourceCenter.y * size.height)
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
