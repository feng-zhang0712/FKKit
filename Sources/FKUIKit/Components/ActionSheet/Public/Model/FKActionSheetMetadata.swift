import Foundation

/// Integrator-defined metadata attached to an action; not interpreted by FKActionSheet.
///
/// Use this to carry your own model without forcing framework-level generics:
/// ```swift
/// var action = FKActionSheetAction(title: "Open")
/// action.metadata = FKActionSheetMetadata(storage: ["item": myItem])
/// ```
public struct FKActionSheetMetadata: @unchecked Sendable {
  /// Keyed storage for arbitrary app models.
  public var storage: [String: Any]

  /// Creates metadata storage.
  public init(storage: [String: Any] = [:]) {
    self.storage = storage
  }

  /// Returns a typed value for a key when the stored type matches.
  public func value<T>(_ type: T.Type = T.self, forKey key: String) -> T? {
    storage[key] as? T
  }
}
