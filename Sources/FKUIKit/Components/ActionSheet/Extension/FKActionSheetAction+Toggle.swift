import UIKit

public extension FKActionSheetAction {
  /// Creates a row with a trailing switch that does not dismiss the sheet when toggled.
  static func toggle(
    id: UUID = UUID(),
    title: String,
    isOn: Bool,
    style: Style = .default,
    isEnabled: Bool = true,
    metadata: FKActionSheetMetadata? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    onValueChanged: @escaping @MainActor (Bool) -> Void
  ) -> FKActionSheetAction {
    var action = FKActionSheetAction(
      id: id,
      title: title,
      style: style,
      isEnabled: isEnabled,
      dismissesSheetWhenSelected: false,
      metadata: metadata,
      accessibilityLabel: accessibilityLabel,
      accessibilityHint: accessibilityHint
    )
    action.rowContent = .toggle(FKActionSheetToggleRow(isOn: isOn))
    action.toggleValueChanged = onValueChanged
    return action
  }
}
