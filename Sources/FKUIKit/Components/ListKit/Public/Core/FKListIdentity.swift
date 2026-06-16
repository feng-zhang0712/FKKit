import Foundation

// MARK: - Item identity

/// Stable string identity for diffable list items across snapshot updates.
public struct FKListItemID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: StringLiteralType) {
    self.rawValue = value
  }

  public var description: String { rawValue }
}

// MARK: - Section identity

/// Stable string identity for diffable list sections across snapshot updates.
public struct FKListSectionID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: StringLiteralType) {
    self.rawValue = value
  }

  public var description: String { rawValue }
}

// MARK: - Payload

/// Type-erased `Sendable` container for custom cell payloads.
///
/// Store heavy payloads in the view controller item store; diffable identity uses ``FKListItemID`` only.
public struct FKListItemPayload: @unchecked Sendable {
  private let box: Any

  public init<T: Sendable>(_ value: T) {
    self.box = value
  }

  /// Returns the wrapped value when its runtime type matches `type`.
  public func unwrap<T>(_ type: T.Type = T.self) -> T? {
    box as? T
  }
}
