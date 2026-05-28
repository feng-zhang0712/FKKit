import UIKit

public extension FKSheetPresentationConfiguration {
  /// Effects applied to the presenting view controller while content is shown.
  struct PresentingViewEffectConfiguration: Sendable, Equatable {
    /// Enables presenting-view effects.
    public var isEnabled: Bool
    /// Scale applied to presenting view at peak presentation.
    public var scale: CGFloat

    /// Creates presenting-view effects.
    ///
    /// - Important: When enabled, FK will apply a scale transform to the presenting view.
    ///   This is disabled by default to avoid surprising apps with custom container hierarchies.
    public init(
      isEnabled: Bool = false,
      scale: CGFloat = 0.97
    ) {
      self.isEnabled = isEnabled
      self.scale = min(max(scale, 0.85), 1)
    }
  }
}

