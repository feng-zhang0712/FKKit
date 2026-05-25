import UIKit

/// Optional haptic feedback when action rows are tapped. Disabled by default.
public struct FKActionSheetHapticsConfiguration: Sendable, Equatable {
  /// When `true`, triggers impact feedback on row selection.
  public var onActionSelection: Bool
  /// Impact style used for row selection.
  public var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle

  /// Creates haptics configuration (off by default).
  public init(
    onActionSelection: Bool = false,
    impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
  ) {
    self.onActionSelection = onActionSelection
    self.impactStyle = impactStyle
  }
}

extension FKActionSheetHapticsConfiguration: @unchecked Sendable {}
