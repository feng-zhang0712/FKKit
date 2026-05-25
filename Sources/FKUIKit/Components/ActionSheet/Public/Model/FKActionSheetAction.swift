import UIKit

/// A single selectable row in an action sheet.
public struct FKActionSheetAction: Identifiable, Equatable {
  /// Visual and behavioral style aligned with `UIAlertAction.Style`.
  public enum Style: Equatable, Sendable {
    /// Standard action styling.
    case `default`
    /// Destructive action styling (typically red).
    case destructive
    /// Cancel action styling; usually placed in a separate group.
    case cancel
  }

  /// Stable row identity used for diffing and updates.
  public let id: UUID
  /// How the row is rendered.
  public var rowContent: FKActionSheetRowContent
  /// Primary label (standard and toggle rows).
  public var title: String
  /// Optional secondary line below the title (standard rows only).
  public var subtitle: String?
  /// Optional leading symbol or image (standard rows only).
  public var image: UIImage?
  /// Row style.
  public var style: Style
  /// When `false`, taps are ignored.
  public var isEnabled: Bool
  /// Selection state for single-selection groups (check, radio, and/or highlighted title).
  public var isSelected: Bool
  /// Shows a trailing activity indicator and blocks taps (standard rows only).
  public var isLoading: Bool
  /// Overrides ``FKActionSheetConfiguration/dismissesAfterActionSelection`` for this row when set.
  public var dismissesSheetWhenSelected: Bool?
  /// Optional integrator metadata (for example your own model).
  public var metadata: FKActionSheetMetadata?
  /// Optional VoiceOver label override.
  public var accessibilityLabel: String?
  /// Optional VoiceOver hint.
  public var accessibilityHint: String?
  /// Invoked according to ``FKActionSheetConfiguration/handlerTiming`` (no parameters).
  ///
  /// When ``actionHandler`` is also set, only ``actionHandler`` runs via ``invokeHandlers()``.
  public var handler: (@MainActor () -> Void)?
  /// Invoked according to ``FKActionSheetConfiguration/handlerTiming`` with this action.
  ///
  /// Takes precedence over ``handler`` when both are set.
  public var actionHandler: (@MainActor (FKActionSheetAction) -> Void)?
  /// Invoked when a toggle row switch changes (toggle rows only).
  public var toggleValueChanged: (@MainActor (Bool) -> Void)?

  /// Creates a standard action sheet row.
  public init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    image: UIImage? = nil,
    style: Style = .default,
    isEnabled: Bool = true,
    isSelected: Bool = false,
    isLoading: Bool = false,
    dismissesSheetWhenSelected: Bool? = nil,
    metadata: FKActionSheetMetadata? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    handler: (@MainActor () -> Void)? = nil,
    actionHandler: (@MainActor (FKActionSheetAction) -> Void)? = nil
  ) {
    self.id = id
    self.rowContent = .standard
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.style = style
    self.isEnabled = isEnabled
    self.isSelected = isSelected
    self.isLoading = isLoading
    self.dismissesSheetWhenSelected = dismissesSheetWhenSelected
    self.metadata = metadata
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.handler = handler
    self.actionHandler = actionHandler
    self.toggleValueChanged = nil
  }

  /// Creates a custom-content row.
  public init(
    id: UUID = UUID(),
    customRow: FKActionSheetCustomRow,
    style: Style = .default,
    isEnabled: Bool = true,
    dismissesSheetWhenSelected: Bool? = nil,
    metadata: FKActionSheetMetadata? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    handler: (@MainActor () -> Void)? = nil,
    actionHandler: (@MainActor (FKActionSheetAction) -> Void)? = nil
  ) {
    self.id = id
    var row = customRow
    row.id = id
    self.rowContent = .custom(row)
    self.title = ""
    self.subtitle = nil
    self.image = nil
    self.style = style
    self.isEnabled = isEnabled
    self.isSelected = false
    self.isLoading = false
    self.dismissesSheetWhenSelected = dismissesSheetWhenSelected
    self.metadata = metadata
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.handler = handler
    self.actionHandler = actionHandler
    self.toggleValueChanged = nil
  }

  /// Whether this row is a toggle row.
  public var isToggleRow: Bool {
    if case .toggle = rowContent { return true }
    return false
  }

  /// Compares identity and visible row state; handler closures are intentionally excluded.
  public static func == (lhs: FKActionSheetAction, rhs: FKActionSheetAction) -> Bool {
    lhs.id == rhs.id
      && lhs.rowContent == rhs.rowContent
      && lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle
      && lhs.image == rhs.image
      && lhs.style == rhs.style
      && lhs.isEnabled == rhs.isEnabled
      && lhs.isSelected == rhs.isSelected
      && lhs.isLoading == rhs.isLoading
      && lhs.dismissesSheetWhenSelected == rhs.dismissesSheetWhenSelected
      && lhs.accessibilityLabel == rhs.accessibilityLabel
      && lhs.accessibilityHint == rhs.accessibilityHint
  }
}
