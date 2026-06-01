import UIKit

/// Trailing accessory rendered beside tab item content (for example filter chevrons).
public struct FKTabBarAccessoryConfiguration: Equatable {
  /// Accessory kind.
  public enum Kind: Equatable, Sendable {
    case none
    /// Built-in chevron; expanded visual state follows ``FKTabBar/expandedItemID``.
    case chevron(FKTabBarChevronAccessoryConfiguration)
    /// Host supplies the view via ``FKTabBarCustomization/customAccessoryView(for:isSelected:isExpanded:)``.
    case custom(id: String)
  }

  /// Accessory variant.
  public var kind: Kind
  /// Spacing between tab content and a ``Kind/custom`` accessory view.
  public var spacing: CGFloat

  /// Creates an accessory configuration.
  public init(kind: Kind = .none, spacing: CGFloat = 4) {
    self.kind = kind
    self.spacing = max(0, spacing)
  }

  /// Creates a chevron accessory with the given chevron configuration.
  public init(chevron: FKTabBarChevronAccessoryConfiguration) {
    self.kind = .chevron(chevron)
    self.spacing = 4
  }
}

extension FKTabBarAccessoryConfiguration: @unchecked Sendable {}

public extension FKTabBarAccessoryConfiguration {
  /// Resolved chevron configuration when ``kind`` is ``Kind/chevron(_:)``.
  var chevronConfiguration: FKTabBarChevronAccessoryConfiguration? {
    if case .chevron(let configuration) = kind { return configuration }
    return nil
  }
}
