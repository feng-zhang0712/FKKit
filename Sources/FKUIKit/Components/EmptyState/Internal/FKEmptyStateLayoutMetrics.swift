import UIKit

/// Derives spacing and typography scale from ``FKEmptyStateDensity``.
///
/// ``spacing(from:)`` scales the fallback ``FKEmptyStateLayoutConfiguration/verticalSpacing`` preset.
/// Explicit ``FKEmptyStateSpacingConfiguration`` values are applied as-is and are not passed through this helper.
struct FKEmptyStateLayoutMetrics {
  let density: FKEmptyStateDensity

  init(density: FKEmptyStateDensity) {
    self.density = density
  }

  func spacing(from base: CGFloat) -> CGFloat {
    switch density {
    case .compact:
      return max(0, base * 0.75)
    case .regular:
      return base
    case .comfortable:
      return base * 1.25
    }
  }

  /// Resolves a segment override or the density-scaled fallback spacing.
  func segmentSpacing(_ explicit: CGFloat?, fallback: CGFloat) -> CGFloat {
    explicit ?? spacing(from: fallback)
  }

  func titleFont(from base: UIFont) -> UIFont {
    scaledFont(base, factor: fontScale)
  }

  func descriptionFont(from base: UIFont) -> UIFont {
    scaledFont(base, factor: fontScale)
  }

  func horizontalRowSpacing(from base: CGFloat) -> CGFloat {
    switch density {
    case .compact:
      return max(8, base * 0.85)
    case .regular:
      return base
    case .comfortable:
      return base * 1.15
    }
  }

  func imageSize(from base: CGSize) -> CGSize {
    switch density {
    case .compact:
      return CGSize(width: max(32, base.width * 0.85), height: max(32, base.height * 0.85))
    case .regular:
      return base
    case .comfortable:
      return CGSize(width: base.width * 1.1, height: base.height * 1.1)
    }
  }

  private var fontScale: CGFloat {
    switch density {
    case .compact:
      return 0.9
    case .regular:
      return 1
    case .comfortable:
      return 1.1
    }
  }

  private func scaledFont(_ base: UIFont, factor: CGFloat) -> UIFont {
    guard factor != 1 else { return base }
    return base.withSize(max(10, base.pointSize * factor))
  }
}
