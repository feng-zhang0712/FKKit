import UIKit

/// Trailing accessory rendered beside tab item content via ``FKButton/setTrailingImage(_:for:)``.
public struct FKTabBarAccessoryConfiguration: Equatable {
  /// Accessory variant.
  public enum Kind: Equatable, Sendable {
    case none
    /// Trailing icon configured by the host (for example ``chevron.down``, ``heart.fill``).
    case icon(FKTabBarAccessoryIconConfiguration)
  }

  /// Accessory variant.
  public var kind: Kind

  /// Creates an accessory configuration.
  public init(kind: Kind = .none) {
    self.kind = kind
  }

  /// Creates a trailing icon accessory.
  public init(icon: FKTabBarAccessoryIconConfiguration) {
    self.kind = .icon(icon)
  }
}

extension FKTabBarAccessoryConfiguration: @unchecked Sendable {}

public extension FKTabBarAccessoryConfiguration {
  /// Resolved icon configuration when ``kind`` is ``Kind/icon(_:)``.
  var iconConfiguration: FKTabBarAccessoryIconConfiguration? {
    if case .icon(let configuration) = kind { return configuration }
    return nil
  }
}
