import Foundation

/// Controls whether a new callout replaces existing ones or can be shown concurrently.
public enum FKCalloutPresentationPolicy: Sendable, Equatable {
  /// Dismisses any visible callout before presenting the new one (default).
  case replaceActive
  /// Keeps existing callouts visible; each request receives its own handle.
  case allowConcurrent
}
