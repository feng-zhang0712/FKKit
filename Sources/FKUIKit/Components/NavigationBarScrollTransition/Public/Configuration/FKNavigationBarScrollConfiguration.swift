import CoreGraphics
import Foundation

/// Policy for ``FKNavigationBarScrollEngine``.
public struct FKNavigationBarScrollConfiguration: Sendable, Equatable {
  /// Master enable switch. When `false`, scroll updates are ignored.
  public var isEnabled: Bool

  /// Content offset (see ``usesAdjustedContentOffset``) where progress is `0`.
  public var startOffset: CGFloat

  /// Content offset where progress is `1`. Hosts should typically set this to the hero / banner height.
  public var endOffset: CGFloat

  /// When `true`, progress uses `contentOffset.y + adjustedContentInset.top`.
  public var usesAdjustedContentOffset: Bool

  /// When `true`, the engine observes scroll metrics via KVO.
  ///
  /// Set to `false` when the host already forwards scroll events and will call
  /// ``FKNavigationBarScrollEngine/handleScroll()``.
  public var observesAutomatically: Bool

  /// When `true`, interpolated appearances are written to the configured ``applicationTarget``.
  public var appliesAppearanceAutomatically: Bool

  /// Target for automatic appearance writes.
  public var applicationTarget: FKNavigationBarScrollApplicationTarget

  /// When `true`, calls `setNeedsStatusBarAppearanceUpdate()` on the bound view controller after
  /// discrete status-bar flips. The host must still return the resolved style from
  /// `preferredStatusBarStyle`.
  public var updatesStatusBarAppearance: Bool

  /// Progress at which discrete fields (status bar style) flip to the `to` endpoint.
  public var discreteThreshold: CGFloat

  /// Minimum progress delta required before callbacks / automatic apply run again.
  public var progressEpsilon: CGFloat

  /// Creates a configuration with safe defaults for transparent → solid transitions.
  public init(
    isEnabled: Bool = true,
    startOffset: CGFloat = 0,
    endOffset: CGFloat = 88,
    usesAdjustedContentOffset: Bool = true,
    observesAutomatically: Bool = true,
    appliesAppearanceAutomatically: Bool = true,
    applicationTarget: FKNavigationBarScrollApplicationTarget = .navigationItem,
    updatesStatusBarAppearance: Bool = true,
    discreteThreshold: CGFloat = 0.5,
    progressEpsilon: CGFloat = 0.001
  ) {
    self.isEnabled = isEnabled
    self.startOffset = startOffset
    self.endOffset = endOffset
    self.usesAdjustedContentOffset = usesAdjustedContentOffset
    self.observesAutomatically = observesAutomatically
    self.appliesAppearanceAutomatically = appliesAppearanceAutomatically
    self.applicationTarget = applicationTarget
    self.updatesStatusBarAppearance = updatesStatusBarAppearance
    self.discreteThreshold = min(max(discreteThreshold, 0), 1)
    self.progressEpsilon = max(progressEpsilon, 0)
  }

  /// Default configuration (`endOffset` ≈ a short chrome distance; override with hero height).
  public static let `default` = FKNavigationBarScrollConfiguration()
}
