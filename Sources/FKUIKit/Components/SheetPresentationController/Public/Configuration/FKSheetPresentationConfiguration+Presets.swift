import UIKit

public extension FKSheetPresentationConfiguration {
  /// Baseline bottom sheet tuned for common app flows (same values as ``default``).
  @MainActor
  static var bottomSheetDefault: FKSheetPresentationConfiguration {
    FKSheetPresentationConfiguration()
  }

  /// Top-attached sheet with medium/large detents and system-like animation.
  @MainActor
  static var topSheetDefault: FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .topSheet(
      .init(detents: [.fitContent, .medium, .large], initialSelectedDetentIndex: 1)
    )
    return configuration
  }

  /// Centered card modal with fitted sizing and a readable dim backdrop.
  @MainActor
  static var centerCard: FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .center(
      .init(
        size: .fitted(maxSize: .init(width: 460, height: 640)),
        dismissEnabled: false
      )
    )
    configuration.safeAreaPolicy = .containerRespectsSafeArea
    configuration.backdropStyle = .dim(alpha: 0.4)
    configuration.cornerRadius = 14
    return configuration
  }

  /// Compact centered alert-style panel with fixed sizing.
  @MainActor
  static var centerAlert: FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .center(
      .init(
        size: .fixed(.init(width: 320, height: 380)),
        minimumMargins: .init(top: 32, leading: 32, bottom: 32, trailing: 32),
        dismissEnabled: true,
        dismissProgressThreshold: 0.28
      )
    )
    configuration.safeAreaPolicy = .containerRespectsSafeArea
    configuration.backdropStyle = .dim(alpha: 0.45)
    configuration.animation.preset = .systemLike
    return configuration
  }

  /// Bottom sheet configured for passthrough background interaction via the overlay host.
  @MainActor
  static var passthroughOverlay: FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration()
    configuration.backgroundInteraction = .init(isEnabled: true, showsBackdropWhenEnabled: true)
    configuration.backdropStyle = .dim(alpha: 0.12)
    configuration.zeroDimBackdropBehavior = .passthrough
    configuration.sheet.detents = [.fitContent, .medium]
    return configuration
  }
}
