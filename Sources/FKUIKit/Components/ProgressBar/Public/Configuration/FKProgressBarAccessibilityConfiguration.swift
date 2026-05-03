import UIKit

/// VoiceOver strings and “frequent updates” trait for ``FKProgressBar``.
public struct FKProgressBarAccessibilityConfiguration: Sendable {
  /// When non-empty, overrides the default `accessibilityLabel` for the control.
  public var accessibilityCustomLabel: String?
  /// When non-empty, appended as additional hint after system hints.
  public var accessibilityCustomHint: String?
  /// When `true`, exposes `UIAccessibilityTraits.updatesFrequently` while indeterminate or animating.
  public var accessibilityTreatAsFrequentUpdates: Bool

  public init(
    accessibilityCustomLabel: String? = nil,
    accessibilityCustomHint: String? = nil,
    accessibilityTreatAsFrequentUpdates: Bool = true
  ) {
    self.accessibilityCustomLabel = accessibilityCustomLabel
    self.accessibilityCustomHint = accessibilityCustomHint
    self.accessibilityTreatAsFrequentUpdates = accessibilityTreatAsFrequentUpdates
  }
}
