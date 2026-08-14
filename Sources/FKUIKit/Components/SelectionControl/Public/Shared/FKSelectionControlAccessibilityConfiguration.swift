import Foundation

/// VoiceOver overrides shared by selection controls.
public struct FKSelectionControlAccessibilityConfiguration: Sendable, Equatable {
  /// When non-empty, overrides the derived accessibility label.
  public var customLabel: String?
  /// When non-empty, sets `accessibilityHint`.
  public var customHint: String?
  /// Optional group label for ``FKRadioGroup`` (container semantics).
  public var groupLabel: String?

  public init(
    customLabel: String? = nil,
    customHint: String? = nil,
    groupLabel: String? = nil
  ) {
    self.customLabel = customLabel
    self.customHint = customHint
    self.groupLabel = groupLabel
  }
}
