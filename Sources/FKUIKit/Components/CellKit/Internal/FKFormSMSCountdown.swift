import Foundation

/// Manages SMS resend countdown state for form cells (X-17).
@MainActor
final class FKFormSMSCountdown {
  var onTick: ((Int) -> Void)?
  var onFinished: (() -> Void)?

  private var timer: Timer?
  private(set) var remainingSeconds = 0

  func start(seconds: Int) {
    invalidate()
    remainingSeconds = max(1, seconds)
    onTick?(remainingSeconds)
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
      guard let self else {
        timer.invalidate()
        return
      }
      MainActor.assumeIsolated {
        self.tick()
      }
    }
  }

  func invalidate() {
    timer?.invalidate()
    timer = nil
    remainingSeconds = 0
  }

  private func tick() {
    remainingSeconds -= 1
    if remainingSeconds > 0 {
      onTick?(remainingSeconds)
    } else {
      invalidate()
      onFinished?()
    }
  }
}
