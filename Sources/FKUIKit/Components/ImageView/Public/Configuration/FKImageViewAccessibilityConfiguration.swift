import UIKit

/// Accessibility behavior for ``FKImageView``.
public struct FKImageViewAccessibilityConfiguration: Equatable, Sendable {
  /// Explicit VoiceOver label; overrides ``imageDescription`` when set.
  public var label: String?
  /// Host-provided image description used when ``label`` is nil.
  public var imageDescription: String?
  /// When `true`, hides the view from accessibility when showing placeholder-only decorative content.
  public var isDecorative: Bool
  /// Posts `UIAccessibilityLayoutChangedNotification` after a successful load.
  public var announcesLayoutChangeOnSuccess: Bool

  /// Creates accessibility defaults.
  public init(
    label: String? = nil,
    imageDescription: String? = nil,
    isDecorative: Bool = false,
    announcesLayoutChangeOnSuccess: Bool = false
  ) {
    self.label = label
    self.imageDescription = imageDescription
    self.isDecorative = isDecorative
    self.announcesLayoutChangeOnSuccess = announcesLayoutChangeOnSuccess
  }
}
