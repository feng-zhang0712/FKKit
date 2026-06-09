import Foundation

/// A single node in ``FKStepIndicator`` or ``FKTimeline``.
public struct FKFlowStepItem: Sendable, Equatable, Identifiable {
  /// Stable identifier for selection, scrolling, and diffing.
  public var id: String
  /// Primary label.
  public var title: String
  /// Secondary label beneath the title.
  public var subtitle: String?
  /// Optional third line (timeline body text).
  public var caption: String?
  /// Raw timestamp for formatting; timeline primary use.
  public var timestamp: Date?
  /// Pre-formatted timestamp when the host controls locale/time zone.
  public var formattedTimestamp: String?
  /// Visual and accessibility state.
  public var state: FKFlowStepState
  /// Optional icon override; `nil` uses state defaults.
  public var icon: FKFlowStepIcon?
  /// VoiceOver hint override for interactive steps.
  public var accessibilityHint: String?
  /// Per-item interaction override; `nil` uses control defaults.
  public var isInteractive: Bool?

  public init(
    id: String,
    title: String,
    subtitle: String? = nil,
    caption: String? = nil,
    timestamp: Date? = nil,
    formattedTimestamp: String? = nil,
    state: FKFlowStepState = .upcoming,
    icon: FKFlowStepIcon? = nil,
    accessibilityHint: String? = nil,
    isInteractive: Bool? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.caption = caption
    self.timestamp = timestamp
    self.formattedTimestamp = formattedTimestamp
    self.state = state
    self.icon = icon
    self.accessibilityHint = accessibilityHint
    self.isInteractive = isInteractive
  }
}
