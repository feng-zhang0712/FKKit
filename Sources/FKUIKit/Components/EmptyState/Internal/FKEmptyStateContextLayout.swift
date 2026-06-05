import UIKit

/// Factory defaults used to detect explicit layout overrides on ``FKEmptyStateConfiguration``.
enum FKEmptyStateConfigurationDefaults {
  static let maxContentWidth: CGFloat = 320
  static let verticalSpacing: CGFloat = 10
  static let contentInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
  static let contentAlignment = FKEmptyStateContentAlignment.center
}

/// Context-driven layout presets; applied when callers leave matching properties at factory defaults.
enum FKEmptyStateContextLayout {
  struct Preset {
    var imageSize: CGSize
    var maxContentWidth: CGFloat
    var contentInsets: UIEdgeInsets
    var verticalSpacing: CGFloat
    var contentAlignment: FKEmptyStateContentAlignment
  }

  static func preset(for context: FKEmptyStateLayoutContext) -> Preset {
    switch context {
    case .fullPage:
      return Preset(
        imageSize: CGSize(width: 96, height: 96),
        maxContentWidth: 360,
        contentInsets: UIEdgeInsets(top: 32, left: 24, bottom: 32, right: 24),
        verticalSpacing: 16,
        contentAlignment: .center
      )
    case .section:
      return Preset(
        imageSize: CGSize(width: 80, height: 80),
        maxContentWidth: 320,
        contentInsets: FKEmptyStateConfigurationDefaults.contentInsets,
        verticalSpacing: 12,
        contentAlignment: .center
      )
    case .list, .table:
      return Preset(
        imageSize: CGSize(width: 72, height: 72),
        maxContentWidth: 300,
        contentInsets: UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16),
        verticalSpacing: 10,
        contentAlignment: .center
      )
    case .search:
      return Preset(
        imageSize: CGSize(width: 72, height: 72),
        maxContentWidth: 300,
        contentInsets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
        verticalSpacing: 10,
        contentAlignment: .center
      )
    case .detail:
      return Preset(
        imageSize: CGSize(width: 64, height: 64),
        maxContentWidth: 280,
        contentInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
        verticalSpacing: 8,
        contentAlignment: .center
      )
    case .dialog:
      return Preset(
        imageSize: CGSize(width: 56, height: 56),
        maxContentWidth: 260,
        contentInsets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
        verticalSpacing: 8,
        contentAlignment: .center
      )
    case .drawer:
      return Preset(
        imageSize: CGSize(width: 72, height: 72),
        maxContentWidth: 300,
        contentInsets: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20),
        verticalSpacing: 10,
        contentAlignment: .top
      )
    case .card:
      return Preset(
        imageSize: CGSize(width: 48, height: 48),
        maxContentWidth: 240,
        contentInsets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
        verticalSpacing: 8,
        contentAlignment: .center
      )
    }
  }
}

/// Effective layout values after applying context and density to a configuration snapshot.
struct FKEmptyStateResolvedLayout {
  let imageSize: CGSize?
  let maxContentWidth: CGFloat
  let contentInsets: UIEdgeInsets
  let verticalSpacing: CGFloat
  let contentAlignment: FKEmptyStateContentAlignment

  init(configuration: FKEmptyStateConfiguration) {
    let preset = FKEmptyStateContextLayout.preset(for: configuration.context)
    let metrics = FKEmptyStateLayoutMetrics(density: configuration.density)

    if let explicit = configuration.imageSize {
      imageSize = explicit
    } else if configuration.image != nil, !configuration.isImageHidden {
      imageSize = metrics.imageSize(from: preset.imageSize)
    } else {
      imageSize = nil
    }

    maxContentWidth = configuration.maxContentWidth == FKEmptyStateConfigurationDefaults.maxContentWidth
      ? preset.maxContentWidth
      : configuration.maxContentWidth

    contentInsets = Self.insetsMatch(configuration.contentInsets, FKEmptyStateConfigurationDefaults.contentInsets)
      ? preset.contentInsets
      : configuration.contentInsets

    verticalSpacing = configuration.verticalSpacing == FKEmptyStateConfigurationDefaults.verticalSpacing
      ? preset.verticalSpacing
      : configuration.verticalSpacing

    contentAlignment = configuration.contentAlignment == FKEmptyStateConfigurationDefaults.contentAlignment
      ? preset.contentAlignment
      : configuration.contentAlignment
  }

  private static func insetsMatch(_ lhs: UIEdgeInsets, _ rhs: UIEdgeInsets) -> Bool {
    lhs.top == rhs.top && lhs.left == rhs.left && lhs.bottom == rhs.bottom && lhs.right == rhs.right
  }
}
