import UIKit

/// User presence semantics for ``FKPresenceIndicator`` (not order/workflow status — use ``FKStatusPill`` for that).
public enum FKPresenceState: Sendable, Equatable {
  /// Available / online.
  case online
  /// Offline / unavailable.
  case offline
  /// Do not disturb / busy.
  case busy
  /// Away / idle.
  case away
  /// Host-defined presence with explicit color and accessibility copy.
  case custom(FKPresenceCustomState)
}

/// Custom presence payload when ``FKPresenceState/custom(_:)`` is used.
public struct FKPresenceCustomState: @unchecked Sendable, Equatable {
  /// Stable identifier for equality.
  public var identifier: String
  /// Dot fill color.
  public var color: UIColor
  /// VoiceOver label when the indicator is focused independently.
  public var accessibilityLabel: String
  /// When `true`, optional pulse animation may run for this state.
  public var pulses: Bool

  /// Creates a custom presence state.
  public init(
    identifier: String,
    color: UIColor,
    accessibilityLabel: String,
    pulses: Bool = false
  ) {
    self.identifier = identifier
    self.color = color
    self.accessibilityLabel = accessibilityLabel
    self.pulses = pulses
  }
}

extension FKPresenceCustomState {
  public static func == (lhs: FKPresenceCustomState, rhs: FKPresenceCustomState) -> Bool {
    lhs.identifier == rhs.identifier
      && lhs.accessibilityLabel == rhs.accessibilityLabel
      && lhs.pulses == rhs.pulses
  }
}

public extension FKPresenceState {
  /// VoiceOver label describing the presence state.
  var accessibilityLabel: String {
    FKAvatarI18n.presenceAccessibilityLabel(for: self)
  }
}
