import UIKit

/// Trailing accessory rendered beside tab item content (for example filter chevrons).
public struct FKTabBarAccessoryConfiguration: Equatable {
  /// Accessory kind.
  public enum Kind: Equatable, Sendable {
    case none
    /// System chevron; expanded visual state follows ``FKTabBar/expandedItemID``.
    case chevron
    /// Host supplies the view via ``FKTabBarCustomization/customAccessoryView(for:isSelected:isExpanded:)``.
    case custom(id: String)
  }

  /// Accessory variant.
  public var kind: Kind
  /// Spacing between primary content and the accessory.
  public var spacing: CGFloat
  /// Template chevron tint; `nil` uses the resolved label color.
  public var tintColor: UIColor?

  /// Creates an accessory configuration.
  public init(kind: Kind = .none, spacing: CGFloat = 4, tintColor: UIColor? = nil) {
    self.kind = kind
    self.spacing = max(0, spacing)
    self.tintColor = tintColor
  }
}

extension FKTabBarAccessoryConfiguration: @unchecked Sendable {}
