import UIKit

/// Context-driven layout presets; applied when callers leave matching layout properties `nil`.
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
        contentInsets: UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20),
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
    let layout = configuration.layout
    let preset = FKEmptyStateContextLayout.preset(for: layout.context)
    let metrics = FKEmptyStateLayoutMetrics(density: layout.density)

    if let explicit = layout.imageSize {
      imageSize = explicit
    } else if configuration.content.image != nil {
      imageSize = metrics.imageSize(from: preset.imageSize)
    } else {
      imageSize = nil
    }

    maxContentWidth = layout.maxContentWidth ?? preset.maxContentWidth
    contentInsets = layout.contentInsets ?? preset.contentInsets
    verticalSpacing = layout.verticalSpacing ?? preset.verticalSpacing
    contentAlignment = layout.contentAlignment ?? preset.contentAlignment
  }
}
