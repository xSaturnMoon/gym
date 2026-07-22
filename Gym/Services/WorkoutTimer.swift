import Foundation
import Combine

@MainActor
final class WorkoutTimer: ObservableObject {
    enum Phase {
        case exercise
        case rest
        case idle
    }

    @Published var phase: Phase = .idle
    @Published var remainingSeconds: Int = 0
    @Published var isRunning = false
    @Published var currentSet = 1
    @Published var totalSets = 1

    private var timer: Timer?
    private var onRestComplete: (() -> Void)?
    private var onExerciseComplete: (() -> Void)?

    func startExercise(duration: Int, set: Int, total: Int, onComplete: @escaping () -> Void) {
        stop()
        phase = .exercise
        currentSet = set
        totalSets = total
        remainingSeconds = duration
        isRunning = true
        onExerciseComplete = onComplete
        startTicking()
    }

    func startCountdownReps(set: Int, total: Int) {
        stop()
        phase = .exercise
        currentSet = set
        totalSets = total
        remainingSeconds = 0
        isRunning = false
    }

    func startRest(duration: Int, onComplete: @escaping () -> Void) {
        stop()
        phase = .rest
        remainingSeconds = duration
        isRunning = true
        onRestComplete = onComplete
        startTicking()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phase = .idle
        remainingSeconds = 0
    }

    func skipRest() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phase = .idle
        remainingSeconds = 0
        onRestComplete?()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            timer?.invalidate()
            timer = nil
            isRunning = false

            if phase == .rest {
                HapticService.restComplete()
                onRestComplete?()
            } else if phase == .exercise {
                HapticService.success()
                onExerciseComplete?()
            }
            phase = .idle
            return
        }
        remainingSeconds -= 1
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
