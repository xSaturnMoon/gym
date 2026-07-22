import AVFoundation
import Vision
import UIKit
import SwiftUI
import Combine

@MainActor
final class CameraPoseManager: NSObject, ObservableObject {
    @Published var currentSnapshot: BodyPoseSnapshot?
    @Published var alignmentScore: Double = 0
    @Published var isAligned = false
    @Published var permissionGranted = false
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let processingQueue = DispatchQueue(label: "gym.camera.pose", qos: .userInitiated)
    private var cameraFacing: CameraFacing = .front
    private var isProcessing = false
    private var photoDelegate: PhotoDelegate?

    func configure(camera: CameraFacing) async {
        cameraFacing = camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionGranted = granted
            if granted { setupSession() }
            else { errorMessage = "Permesso camera negato." }
        default:
            permissionGranted = false
            errorMessage = "Abilita la camera in Impostazioni."
        }
    }

    func start() {
        let session = session
        processingQueue.async {
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stop() {
        let session = session
        processingQueue.async {
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() async throws -> (UIImage, BodyPoseSnapshot) {
        guard let snapshot = currentSnapshot, isAligned else {
            throw BodyPoseDetectionService.PoseDetectionError.noBodyDetected
        }

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoDelegate { [weak self] result in
                self?.photoDelegate = nil
                switch result {
                case .success(let image):
                    continuation.resume(returning: (image, snapshot))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            photoDelegate = delegate
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        for input in session.inputs { session.removeInput(input) }
        for output in session.outputs { session.removeOutput(output) }

        let position: AVCaptureDevice.Position = cameraFacing == .front ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            errorMessage = "Camera non disponibile."
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }
}

extension CameraPoseManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        Task { @MainActor in
            guard !isProcessing else { return }
            isProcessing = true
            defer { isProcessing = false }

            do {
                let orientation: CGImagePropertyOrientation = cameraFacing == .front ? .leftMirrored : .right
                let snapshot = try await BodyPoseDetectionService.detectPose(
                    in: pixelBuffer,
                    orientation: orientation
                )
                currentSnapshot = snapshot
                alignmentScore = BodyPoseDetectionService.alignmentScore(for: snapshot)
                isAligned = BodyPoseDetectionService.isAlignedForCapture(snapshot)
            } catch {
                currentSnapshot = nil
                alignmentScore = 0
                isAligned = false
            }
        }
    }
}

private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void

    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(error))
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(.failure(BodyPoseDetectionService.PoseDetectionError.invalidImage))
            return
        }
        completion(.success(image))
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

struct PoseGuideOverlay: View {
    let snapshot: BodyPoseSnapshot?
    let alignmentScore: Double
    let isAligned: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, canvasSize in
                    drawGuideSkeleton(context: context, size: canvasSize)
                    if let snapshot {
                        drawDetectedPose(snapshot: snapshot, context: context, size: canvasSize)
                    }
                }

                VStack {
                    alignmentBadge.padding(.top, 16)
                    Spacer()
                    captureHint.padding(.bottom, 120)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var alignmentBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: isAligned ? "checkmark.circle.fill" : "figure.stand")
                .foregroundStyle(isAligned ? .green : .orange)
            Text(isAligned ? "Posa allineata — puoi scattare" : "Allineati alla sagoma (\(Int(alignmentScore * 100))%)")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(
            isAligned ? .regular.tint(.green.opacity(0.2)) : .regular.tint(.orange.opacity(0.2)),
            in: .capsule
        )
    }

    private var captureHint: some View {
        VStack(spacing: 6) {
            Text("Suggerimenti")
                .font(.caption.weight(.bold))
            Text("Stessa camera · Sfondo neutro · Mattina · Braccia leggermente distanziate")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func drawGuideSkeleton(context: GraphicsContext, size: CGSize) {
        for (from, to) in PoseGuideTemplate.connections {
            guard let p1 = PoseGuideTemplate.joints[from], let p2 = PoseGuideTemplate.joints[to] else { continue }
            var path = Path()
            path.move(to: scaled(p1, in: size))
            path.addLine(to: scaled(p2, in: size))
            context.stroke(path, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
        }
        for (_, point) in PoseGuideTemplate.joints {
            let p = scaled(point, in: size)
            let rect = CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)
            context.stroke(Circle().path(in: rect), with: .color(.white.opacity(0.4)), lineWidth: 2)
        }
    }

    private func drawDetectedPose(snapshot: BodyPoseSnapshot, context: GraphicsContext, size: CGSize) {
        for (joint, target) in PoseGuideTemplate.joints {
            guard let detected = snapshot.point(for: joint) else { continue }
            let targetPoint = scaled(target, in: size)
            let detectedPoint = scaled(CGPoint(x: detected.x, y: detected.y), in: size)
            let inRange = hypot(targetPoint.x - detectedPoint.x, targetPoint.y - detectedPoint.y)
                < size.width * PoseGuideTemplate.alignmentTolerance

            var line = Path()
            line.move(to: targetPoint)
            line.addLine(to: detectedPoint)
            context.stroke(line, with: .color(inRange ? .green.opacity(0.7) : .orange.opacity(0.7)), lineWidth: 2)

            let rect = CGRect(x: detectedPoint.x - 6, y: detectedPoint.y - 6, width: 12, height: 12)
            context.fill(Circle().path(in: rect), with: .color(inRange ? .green : .orange))
        }
    }

    private func scaled(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}

struct PhotoCaptureScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var camera = CameraPoseManager()
    @State private var service: ProgressPhotoService?
    @State private var settings: ProgressPhotoSettings?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if camera.permissionGranted {
                    CameraPreviewView(session: camera.session).ignoresSafeArea()
                    PoseGuideOverlay(
                        snapshot: camera.currentSnapshot,
                        alignmentScore: camera.alignmentScore,
                        isAligned: camera.isAligned
                    ).ignoresSafeArea()

                    VStack {
                        Spacer()
                        captureControls
                    }
                } else {
                    EmptyStateView(
                        icon: "camera.fill",
                        title: "Permesso camera necessario",
                        message: camera.errorMessage ?? "Abilita l'accesso alla camera."
                    )
                }
            }
            .navigationTitle("Scatta foto progresso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { camera.stop(); dismiss() }
                }
            }
            .alert("Errore", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                service = ProgressPhotoService(modelContext: modelContext)
                settings = service?.settings()
                await camera.configure(camera: settings?.preferredCamera ?? .front)
                camera.start()
            }
            .onDisappear { camera.stop() }
        }
    }

    private var captureControls: some View {
        VStack(spacing: 16) {
            if settings?.aiAnalysisEnabled == true, !(KeychainHelper.loadGeminiAPIKey() ?? "").isEmpty {
                Label("Foto inviata per analisi al salvataggio", systemImage: "icloud.and.arrow.up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }

            Button { Task { await capturePhoto() } } label: {
                ZStack {
                    Circle().strokeBorder(.white, lineWidth: 4).frame(width: 76, height: 76)
                    Circle()
                        .fill(camera.isAligned ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 62, height: 62)
                }
            }
            .disabled(!camera.isAligned || isSaving)
            .overlay { if isSaving { ProgressView().tint(.white) } }
        }
        .padding(.bottom, 40)
    }

    private func capturePhoto() async {
        guard let service, let settings else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let (image, snapshot) = try await camera.capturePhoto()
            _ = try await service.savePhoto(
                image: image,
                snapshot: snapshot,
                camera: settings.preferredCamera,
                alignmentScore: camera.alignmentScore,
                runAIAnalysis: settings.aiAnalysisEnabled
            )
            HapticService.success()
            camera.stop()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.warning()
        }
    }
}
