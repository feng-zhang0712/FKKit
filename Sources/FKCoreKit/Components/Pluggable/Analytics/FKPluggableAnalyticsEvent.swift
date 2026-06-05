import Foundation

/// Logical analytics / telemetry event for pluggable upload pipelines.
///
/// Distinct from ``FKAnalyticsEvent`` in BusinessKit (which includes ``FKAnalyticsEventType``).
public struct FKPluggableAnalyticsEvent: Sendable, Hashable, Identifiable {
  /// Stable event identifier (UUID recommended for deduplication).
  public var id: String
  /// Event name (for example `page_view`, `button_click`).
  public var name: String
  /// Unix timestamp in seconds.
  public var timestamp: TimeInterval
  /// Merged common + per-event parameters.
  public var parameters: [String: String]

  /// Creates an analytics event.
  public init(
    id: String = UUID().uuidString,
    name: String,
    timestamp: TimeInterval = Date().timeIntervalSince1970,
    parameters: [String: String] = [:]
  ) {
    self.id = id
    self.name = name
    self.timestamp = timestamp
    self.parameters = parameters
  }
}
