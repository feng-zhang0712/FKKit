import UIKit

public extension FKActionSheetAction {
  /// Creates an action with an SF Symbol image resolved at runtime.
  init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    symbolName: String,
    symbolConfiguration: UIImage.SymbolConfiguration? = nil,
    style: Style = .default,
    isEnabled: Bool = true,
    isSelected: Bool = false,
    isLoading: Bool = false,
    dismissesSheetWhenSelected: Bool? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    actionHandler: (@MainActor (FKActionSheetAction) -> Void)? = nil
  ) {
    let image: UIImage?
    if let symbolConfiguration {
      image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)
    } else {
      image = UIImage(systemName: symbolName)
    }
    self.init(
      id: id,
      title: title,
      subtitle: subtitle,
      image: image,
      style: style,
      isEnabled: isEnabled,
      isSelected: isSelected,
      isLoading: isLoading,
      dismissesSheetWhenSelected: dismissesSheetWhenSelected,
      accessibilityLabel: accessibilityLabel,
      accessibilityHint: accessibilityHint,
      actionHandler: actionHandler
    )
  }

  /// Creates a symbol action with a trailing handler closure.
  init(
    id: UUID = UUID(),
    title: String,
    subtitle: String? = nil,
    symbolName: String,
    symbolConfiguration: UIImage.SymbolConfiguration? = nil,
    style: Style = .default,
    isEnabled: Bool = true,
    isSelected: Bool = false,
    isLoading: Bool = false,
    dismissesSheetWhenSelected: Bool? = nil,
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil,
    _ handler: @escaping @MainActor () -> Void
  ) {
    self.init(
      id: id,
      title: title,
      subtitle: subtitle,
      symbolName: symbolName,
      symbolConfiguration: symbolConfiguration,
      style: style,
      isEnabled: isEnabled,
      isSelected: isSelected,
      isLoading: isLoading,
      dismissesSheetWhenSelected: dismissesSheetWhenSelected,
      accessibilityLabel: accessibilityLabel,
      accessibilityHint: accessibilityHint,
      actionHandler: { _ in handler() }
    )
  }
}
