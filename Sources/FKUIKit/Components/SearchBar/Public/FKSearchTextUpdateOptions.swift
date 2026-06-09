import Foundation

/// Options for programmatic text updates on search controls.
public struct FKSearchTextUpdateOptions: Sendable, Equatable {
  /// When `true`, raw and debounced callbacks are skipped.
  public var suppressEvents: Bool
  /// When `true`, immediately emits `searchQueryChanged` with the normalized value.
  public var triggerSearchQueryChanged: Bool

  public init(suppressEvents: Bool = false, triggerSearchQueryChanged: Bool = false) {
    self.suppressEvents = suppressEvents
    self.triggerSearchQueryChanged = triggerSearchQueryChanged
  }

  /// Updates text without firing callbacks.
  public static let silent = FKSearchTextUpdateOptions(suppressEvents: true, triggerSearchQueryChanged: false)

  /// Updates text and immediately emits a debounced query callback.
  public static let withSearchQuery = FKSearchTextUpdateOptions(suppressEvents: false, triggerSearchQueryChanged: true)
}
