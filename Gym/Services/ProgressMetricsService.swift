import UIKit
import CoreImage

@MainActor
enum ProgressMetricsService {
    static func calculate(from snapshot: BodyPoseSnapshot, image: UIImage) -> BodyMetrics {
        let shoulderWidth = lineLength(snapshot, "left_shoulder", "right_shoulder")
        let hipWidth = lineLength(snapshot, "left_hip", "right_hip")
        let torsoLength = midlineLength(
            snapshot,
            top: ("left_shoulder", "right_shoulder"),
            bottom: ("left_hip", "right_hip")
        )

        let shoulderAngle = lineAngle(snapshot, "left_shoulder", "right_shoulder")
        let hipAngle = lineAngle(snapshot, "left_hip", "right_hip")

        let abdomenDef = regionDefinition(image: image, snapshot: snapshot, region: .abdomen)
        let armsDef = regionDefinition(image: image, snapshot: snapshot, region: .arms)
        let legsDef = regionDefinition(image: image, snapshot: snapshot, region: .legs)

        let posture = postureScore(shoulderAngle: shoulderAngle, hipAngle: hipAngle)

        let ratio = hipWidth > 0.001 ? shoulderWidth / hipWidth : 1.0

        return BodyMetrics(
            shoulderWidth: shoulderWidth,
            hipWidth: hipWidth,
            shoulderToHipRatio: ratio,
            shoulderAlignmentDegrees: abs(shoulderAngle * 180 / .pi),
            hipAlignmentDegrees: abs(hipAngle * 180 / .pi),
            torsoLength: torsoLength,
            abdomenDefinition: abdomenDef,
            armsDefinition: armsDef,
            legsDefinition: legsDef,
            postureScore: posture
        )
    }

    static func descriptiveBaselineReport(metrics: BodyMetrics) -> [String] {
        var lines: [String] = []
        lines.append("Rapporto spalle/fianchi: \(String(format: "%.2f", metrics.shoulderToHipRatio))")
        lines.append("Allineamento spalle: \(String(format: "%.1f", metrics.shoulderAlignmentDegrees))° dalla orizzontale")
        lines.append("Allineamento bacino: \(String(format: "%.1f", metrics.hipAlignmentDegrees))° dalla orizzontale")
        lines.append("Definizione addome: \(definitionLabel(metrics.abdomenDefinition))")
        lines.append("Definizione braccia: \(definitionLabel(metrics.armsDefinition))")
        lines.append("Definizione gambe: \(definitionLabel(metrics.legsDefinition))")
        lines.append("Postura generale: \(postureLabel(metrics.postureScore))")
        return lines
    }

    static func metricChanges(current: BodyMetrics, baseline: BodyMetrics) -> [String] {
        var changes: [String] = []
        let delta = current.delta(from: baseline)

        if abs(delta["shoulderAlignmentDegrees"] ?? 0) > 1.5 {
            let improved = (delta["shoulderAlignmentDegrees"] ?? 0) < 0
            changes.append(improved
                ? "Spalle più dritte rispetto alla baseline"
                : "Leggera inclinazione delle spalle rispetto alla baseline")
        }

        if abs(delta["hipAlignmentDegrees"] ?? 0) > 1.5 {
            let improved = (delta["hipAlignmentDegrees"] ?? 0) < 0
            changes.append(improved
                ? "Bacino più allineato rispetto alla baseline"
                : "Bacino leggermente inclinato rispetto alla baseline")
        }

        if abs(delta["abdomenDefinition"] ?? 0) > 0.05 {
            let improved = (delta["abdomenDefinition"] ?? 0) > 0
            changes.append(improved
                ? "Definizione addominale leggermente più visibile"
                : "Definizione addominale leggermente meno visibile")
        }

        if abs(delta["armsDefinition"] ?? 0) > 0.05 {
            let improved = (delta["armsDefinition"] ?? 0) > 0
            changes.append(improved
                ? "Maggiore definizione visibile nelle braccia"
                : "Minore definizione visibile nelle braccia")
        }

        if abs(delta["legsDefinition"] ?? 0) > 0.05 {
            let improved = (delta["legsDefinition"] ?? 0) > 0
            changes.append(improved
                ? "Maggiore definizione visibile nelle gambe"
                : "Minore definizione visibile nelle gambe")
        }

        if abs(delta["postureScore"] ?? 0) > 0.05 {
            let improved = (delta["postureScore"] ?? 0) > 0
            changes.append(improved
                ? "Miglioramento della postura generale"
                : "Leggero peggioramento della postura")
        }

        return changes
    }

    // MARK: - Private

    private enum BodyRegion { case abdomen, arms, legs }

    private static func lineLength(_ snapshot: BodyPoseSnapshot, _ a: String, _ b: String) -> Double {
        guard let p1 = snapshot.cgPoint(for: a), let p2 = snapshot.cgPoint(for: b) else { return 0 }
        return Double(hypot(p1.x - p2.x, p1.y - p2.y))
    }

    private static func lineAngle(_ snapshot: BodyPoseSnapshot, _ a: String, _ b: String) -> Double {
        guard let p1 = snapshot.cgPoint(for: a), let p2 = snapshot.cgPoint(for: b) else { return 0 }
        return Double(atan2(p2.y - p1.y, p2.x - p1.x))
    }

    private static func midlineLength(
        _ snapshot: BodyPoseSnapshot,
        top: (String, String),
        bottom: (String, String)
    ) -> Double {
        guard let t1 = snapshot.cgPoint(for: top.0), let t2 = snapshot.cgPoint(for: top.1),
              let b1 = snapshot.cgPoint(for: bottom.0), let b2 = snapshot.cgPoint(for: bottom.1) else { return 0 }
        let topMid = CGPoint(x: (t1.x + t2.x) / 2, y: (t1.y + t2.y) / 2)
        let bottomMid = CGPoint(x: (b1.x + b2.x) / 2, y: (b1.y + b2.y) / 2)
        return Double(hypot(topMid.x - bottomMid.x, topMid.y - bottomMid.y))
    }

    private static func postureScore(shoulderAngle: Double, hipAngle: Double) -> Double {
        let shoulderDev = min(abs(shoulderAngle), .pi / 2)
        let hipDev = min(abs(hipAngle), .pi / 2)
        let combined = (shoulderDev + hipDev) / 2
        return max(0, 1 - combined / (.pi / 8))
    }

    private static func regionDefinition(image: UIImage, snapshot: BodyPoseSnapshot, region: BodyRegion) -> Double {
        guard let cgImage = image.cgImage else { return 0.5 }
        let rect = bodyRegionRect(snapshot: snapshot, region: region)
        guard rect.width > 0.01, rect.height > 0.01 else { return 0.5 }

        let cropRect = CGRect(
            x: rect.origin.x * CGFloat(cgImage.width),
            y: rect.origin.y * CGFloat(cgImage.height),
            width: rect.width * CGFloat(cgImage.width),
            height: rect.height * CGFloat(cgImage.height)
        ).integral

        guard let cropped = cgImage.cropping(to: cropRect) else { return 0.5 }
        let ciImage = CIImage(cgImage: cropped)
        let edges = ciImage.applyingFilter("CIEdges", parameters: ["inputIntensity": 2.0])
        let extent = edges.extent
        guard extent.width > 0, extent.height > 0 else { return 0.5 }

        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            edges,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: extent.midX, y: extent.midY, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        let edgeIntensity = Double(bitmap[0]) / 255.0
        return min(1, max(0, 0.3 + edgeIntensity * 0.7))
    }

    private static func bodyRegionRect(snapshot: BodyPoseSnapshot, region: BodyRegion) -> CGRect {
        switch region {
        case .abdomen:
            guard let ls = snapshot.cgPoint(for: "left_shoulder"),
                  let rs = snapshot.cgPoint(for: "right_shoulder"),
                  let lh = snapshot.cgPoint(for: "left_hip"),
                  let rh = snapshot.cgPoint(for: "right_hip") else { return .zero }
            let minX = min(ls.x, rs.x, lh.x, rh.x)
            let maxX = max(ls.x, rs.x, lh.x, rh.x)
            let topY = (ls.y + rs.y) / 2
            let bottomY = (lh.y + rh.y) / 2
            return CGRect(x: minX, y: topY, width: maxX - minX, height: bottomY - topY)
        case .arms:
            guard let ls = snapshot.cgPoint(for: "left_shoulder"),
                  let rs = snapshot.cgPoint(for: "right_shoulder"),
                  let lw = snapshot.cgPoint(for: "left_wrist"),
                  let rw = snapshot.cgPoint(for: "right_wrist") else { return .zero }
            let minX = min(lw.x, ls.x, rs.x, rw.x)
            let maxX = max(lw.x, ls.x, rs.x, rw.x)
            let minY = min(lw.y, ls.y, rs.y, rw.y)
            let maxY = max(lw.y, ls.y, rs.y, rw.y)
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        case .legs:
            guard let lh = snapshot.cgPoint(for: "left_hip"),
                  let rh = snapshot.cgPoint(for: "right_hip"),
                  let la = snapshot.cgPoint(for: "left_ankle"),
                  let ra = snapshot.cgPoint(for: "right_ankle") else { return .zero }
            let minX = min(lh.x, rh.x, la.x, ra.x)
            let maxX = max(lh.x, rh.x, la.x, ra.x)
            let topY = (lh.y + rh.y) / 2
            let bottomY = max(la.y, ra.y)
            return CGRect(x: minX, y: topY, width: maxX - minX, height: bottomY - topY)
        }
    }

    private static func definitionLabel(_ value: Double) -> String {
        switch value {
        case 0.7...: "Marcata"
        case 0.55..<0.7: "Visibile"
        case 0.4..<0.55: "Moderata"
        default: "Leggera"
        }
    }

    private static func postureLabel(_ value: Double) -> String {
        switch value {
        case 0.8...: "Ottima"
        case 0.6..<0.8: "Buona"
        case 0.4..<0.6: "Discreta"
        default: "Da migliorare"
        }
    }
}
