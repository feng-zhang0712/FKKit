import Foundation

/// Stable reference to one presented callout; safe to pass across concurrency domains.
public final class FKCalloutHandle: Sendable {
  /// Identifier shared with ``FKCallout/dismiss(_:reason:animated:)``.
  public let id: UUID

  init(id: UUID) {
    self.id = id
  }

  /// Dismisses this callout when it is still active.
  @MainActor
  public func dismiss(reason: FKCalloutDismissReason = .manual, animated: Bool = true) {
    FKCallout.dismiss(id, reason: reason, animated: animated)
  }

  /// Replaces visible content without re-presenting.
  @MainActor
  @discardableResult
  public func update(content: FKCalloutContent, configuration: FKCalloutConfiguration? = nil) -> Bool {
    FKCallout.update(id, content: content, configuration: configuration)
  }
}
