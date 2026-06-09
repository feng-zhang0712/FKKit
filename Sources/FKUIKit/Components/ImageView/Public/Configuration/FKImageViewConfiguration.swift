import FKCoreKit
import UIKit

/// Aggregate configuration for ``FKImageView``.
public struct FKImageViewConfiguration: @unchecked Sendable {
  /// Visual styling.
  public var appearance: FKImageViewAppearanceConfiguration
  /// Loading and placeholder behavior.
  public var loading: FKImageViewLoadingConfiguration
  /// Failure and retry presentation.
  public var failure: FKImageViewFailureConfiguration
  /// Intrinsic sizing hints.
  public var layout: FKImageViewLayoutConfiguration
  /// VoiceOver and announcements.
  public var accessibility: FKImageViewAccessibilityConfiguration
  /// Tap highlight and retry debounce.
  public var interaction: FKImageViewInteractionConfiguration

  /// Creates a full configuration with nested defaults.
  public init(
    appearance: FKImageViewAppearanceConfiguration = .init(),
    loading: FKImageViewLoadingConfiguration = .init(),
    failure: FKImageViewFailureConfiguration = .init(),
    layout: FKImageViewLayoutConfiguration = .init(),
    accessibility: FKImageViewAccessibilityConfiguration = .init(),
    interaction: FKImageViewInteractionConfiguration = .init()
  ) {
    self.appearance = appearance
    self.loading = loading
    self.failure = failure
    self.layout = layout
    self.accessibility = accessibility
    self.interaction = interaction
  }
}

/// Process-wide defaults for new ``FKImageView`` instances.
@MainActor
public enum FKImageViewDefaults {
  /// Baseline configuration copied at initialization.
  public static var defaultConfiguration = FKImageViewConfiguration()
  /// Shared loader used when ``FKImageView/imageLoader`` is nil.
  public static var sharedImageLoader: any FKImageLoading = FKImageLoader.shared
}
