import UIKit

/// SF Symbol weight for the built-in chevron accessory.
public enum FKTabBarChevronSymbolWeight: Equatable, Sendable {
  case regular
  case medium
  case semibold
  case bold

  var uiImageWeight: UIImage.SymbolWeight {
    switch self {
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    }
  }
}

/// Visual configuration for ``FKTabBarAccessoryConfiguration/Kind/chevron(_:)``.
public struct FKTabBarChevronAccessoryConfiguration: Equatable {
  /// Point size for the SF Symbol chevron.
  public var pointSize: CGFloat
  /// Symbol weight.
  public var weight: FKTabBarChevronSymbolWeight
  /// Optional fixed layout size; `nil` uses a square of ``pointSize``.
  public var fixedSize: CGSize?
  /// Spacing between title/icon content and the chevron.
  public var spacing: CGFloat
  /// Template tint; `nil` uses the resolved label color.
  public var tintColor: UIColor?

  /// Creates a chevron accessory configuration.
  ///
  /// Built-in chevrons always render ``chevron.down``; ``FKTabBar`` does not swap symbols or apply transforms.
  /// Host code (for example via ``FKTabBar/visibleItemButton(at:)``) owns expansion visuals and animations.
  public init(
    pointSize: CGFloat = 14,
    weight: FKTabBarChevronSymbolWeight = .semibold,
    fixedSize: CGSize? = nil,
    spacing: CGFloat = 4,
    tintColor: UIColor? = nil
  ) {
    self.pointSize = max(1, pointSize)
    self.weight = weight
    self.fixedSize = fixedSize
    self.spacing = max(0, spacing)
    self.tintColor = tintColor
  }
}

extension FKTabBarChevronAccessoryConfiguration: @unchecked Sendable {}
