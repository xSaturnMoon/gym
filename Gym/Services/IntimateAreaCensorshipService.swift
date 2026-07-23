import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum IntimateAreaCensorshipService {
    private static let context = CIContext()

    /// Applica pixelatura su torace e zona pelvica usando i landmark corporei.
    static func censor(image: UIImage, snapshot: BodyPoseSnapshot) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let regions = censorshipRegions(for: snapshot, imageSize: imageSize)
        guard !regions.isEmpty else { return image }

        var output = CIImage(cgImage: cgImage)
        for region in regions {
            output = pixelate(region: region, in: output)
        }

        guard let result = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: result, scale: image.scale, orientation: image.imageOrientation)
    }

    static func censoredJPEGData(from image: UIImage, snapshot: BodyPoseSnapshot, quality: CGFloat = 0.85) -> Data? {
        censor(image: image, snapshot: snapshot).jpegData(compressionQuality: quality)
    }

    private struct CensorshipRegion {
        let center: CGPoint
        let width: CGFloat
        let height: CGFloat
    }

    private static func censorshipRegions(for snapshot: BodyPoseSnapshot, imageSize: CGSize) -> [CensorshipRegion] {
        var regions: [CensorshipRegion] = []

        if let chest = chestRegion(for: snapshot, imageSize: imageSize) {
            regions.append(chest)
        }
        if let pelvic = pelvicRegion(for: snapshot, imageSize: imageSize) {
            regions.append(pelvic)
        }
        return regions
    }

    private static func chestRegion(for snapshot: BodyPoseSnapshot, imageSize: CGSize) -> CensorshipRegion? {
        guard
            let leftShoulder = snapshot.point(for: "left_shoulder"),
            let rightShoulder = snapshot.point(for: "right_shoulder"),
            let leftHip = snapshot.point(for: "left_hip"),
            let rightHip = snapshot.point(for: "right_hip")
        else { return nil }

        let shoulderY = (leftShoulder.y + rightShoulder.y) / 2
        let hipY = (leftHip.y + rightHip.y) / 2
        let torsoLength = abs(hipY - shoulderY)
        guard torsoLength > 0.05 else { return nil }

        let centerX = ((leftShoulder.x + rightShoulder.x) / 2) * imageSize.width
        let centerY = (shoulderY + torsoLength * 0.38) * imageSize.height
        let width = abs(leftShoulder.x - rightShoulder.x) * imageSize.width * 0.95
        let height = torsoLength * imageSize.height * 0.32

        return CensorshipRegion(
            center: CGPoint(x: centerX, y: centerY),
            width: max(width, imageSize.width * 0.14),
            height: max(height, imageSize.height * 0.08)
        )
    }

    private static func pelvicRegion(for snapshot: BodyPoseSnapshot, imageSize: CGSize) -> CensorshipRegion? {
        guard let leftHip = snapshot.point(for: "left_hip"),
              let rightHip = snapshot.point(for: "right_hip") else { return nil }

        let hipWidth = abs(leftHip.x - rightHip.x) * imageSize.width
        let hipMidY = (leftHip.y + rightHip.y) / 2

        let kneeMidY: Double = if
            let leftKnee = snapshot.point(for: "left_knee"),
            let rightKnee = snapshot.point(for: "right_knee") {
            (leftKnee.y + rightKnee.y) / 2
        } else {
            hipMidY + 0.12
        }

        let centerX = ((leftHip.x + rightHip.x) / 2) * imageSize.width
        let centerY = (hipMidY + (kneeMidY - hipMidY) * 0.35) * imageSize.height
        let height = abs(kneeMidY - hipMidY) * imageSize.height * 0.55

        return CensorshipRegion(
            center: CGPoint(x: centerX, y: centerY),
            width: max(hipWidth * 1.1, imageSize.width * 0.12),
            height: max(height, imageSize.height * 0.1)
        )
    }

    private static func pixelate(region: CensorshipRegion, in image: CIImage) -> CIImage {
        let rect = CGRect(
            x: region.center.x - region.width / 2,
            y: image.extent.height - region.center.y - region.height / 2,
            width: region.width,
            height: region.height
        ).intersection(image.extent)

        guard !rect.isNull, rect.width > 1, rect.height > 1 else { return image }

        let cropped = image.cropped(to: rect)
        let scale = max(8, min(rect.width, rect.height) * 0.12)
        let pixellated = cropped
            .applyingFilter("CIPixellate", parameters: [
                kCIInputScaleKey: scale,
                kCIInputCenterKey: CIVector(x: rect.midX, y: rect.midY),
            ])
            .cropped(to: rect)

        let mask = radialMask(in: rect)
        return pixellated.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask,
        ])
    }

    private static func radialMask(in rect: CGRect) -> CIImage {
        let filter = CIFilter.radialGradient()
        filter.center = CGPoint(x: rect.midX, y: rect.midY)
        filter.radius0 = Float(min(rect.width, rect.height) * 0.2)
        filter.radius1 = Float(max(rect.width, rect.height) * 0.55)
        filter.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        filter.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        return filter.outputImage?.cropped(to: rect) ?? CIImage.empty()
    }
}
