import UIKit

/// Lazily prepares impact feedback when haptics are enabled on the configuration.
@MainActor
final class FKActionSheetHaptics {
  private var generator: UIImpactFeedbackGenerator?

  func prepare(configuration: FKActionSheetHapticsConfiguration) {
    guard configuration.onActionSelection else {
      generator = nil
      return
    }
    let impact = UIImpactFeedbackGenerator(style: configuration.impactStyle)
    impact.prepare()
    generator = impact
  }

  func playSelection() {
    generator?.impactOccurred()
  }
}
