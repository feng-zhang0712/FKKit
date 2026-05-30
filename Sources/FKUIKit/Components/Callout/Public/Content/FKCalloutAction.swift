import UIKit

/// Action button shown inside a callout footer (for example "Learn more" or "Got it").
public struct FKCalloutAction: Sendable, Equatable, Identifiable {
  /// Visual emphasis of the action.
  public enum Style: Sendable, Equatable {
    /// Bordered secondary action.
    case `default`
    /// Filled primary action.
    case primary
  }

  /// Stable identifier used to match ``FKCalloutBuilder/actionHandlers`` entries.
  public var id: String
  /// Button title.
  public var title: String
  /// Visual style.
  public var style: Style
  /// Optional accessibility label override.
  public var accessibilityLabel: String?

  /// Creates an action descriptor. Pair handlers with ``id``; ``title`` remains supported for legacy call sites.
  public init(
    id: String = UUID().uuidString,
    title: String,
    style: Style = .default,
    accessibilityLabel: String? = nil
  ) {
    self.id = id
    self.title = title
    self.style = style
    self.accessibilityLabel = accessibilityLabel
  }
}
