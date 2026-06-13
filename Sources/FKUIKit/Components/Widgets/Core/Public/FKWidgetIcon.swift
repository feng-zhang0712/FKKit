import FKCoreKit
import UIKit

/// Shared leading icon payload for widget capsules (Chip, Tag, StatusPill).
public enum FKWidgetIcon: Sendable, Equatable {
  /// SF Symbol rendered with optional configuration.
  case symbol(name: String, configuration: UIImage.Configuration? = nil)
  /// Host-provided bitmap (template tint applied when configured).
  case image(UIImage)
}

extension FKWidgetIcon {
  /// Renders a template image sized for ``UIImageView`` tinting (preferred for UIKit widgets).
  @MainActor
  func resolvedTemplateImage(pointSize: CGFloat, weight: UIImage.SymbolWeight = .medium) -> UIImage? {
    switch self {
    case .symbol(let name, let config):
      let symbolConfig = config ?? UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
      return UIImage(systemName: name, withConfiguration: symbolConfig)?
        .withRenderingMode(.alwaysTemplate)
    case .image(let image):
      return image.withRenderingMode(.alwaysTemplate)
    }
  }

  /// Renders the icon at the requested point size.
  ///
  /// When `tintColor` is non-`nil`, returns a template image — apply the tint on the hosting
  /// ``UIImageView`` to avoid bitmap edge artifacts from pre-tinting.
  @MainActor
  func resolvedImage(pointSize: CGFloat, weight: UIImage.SymbolWeight = .medium, tintColor: UIColor?) -> UIImage? {
    resolvedTemplateImage(pointSize: pointSize, weight: weight)
  }
}

extension FKWidgetIcon {
  public static func == (lhs: FKWidgetIcon, rhs: FKWidgetIcon) -> Bool {
    switch (lhs, rhs) {
    case (.symbol(let lName, _), .symbol(let rName, _)):
      lName == rName
    case (.image(let lImage), .image(let rImage)):
      lImage === rImage
    default:
      false
    }
  }
}

/// Chip leading icon alias.
public typealias FKChipIcon = FKWidgetIcon

/// Tag leading icon alias.
public typealias FKTagIcon = FKWidgetIcon

/// Icon view content alias.
public typealias FKIconViewIcon = FKWidgetIcon
