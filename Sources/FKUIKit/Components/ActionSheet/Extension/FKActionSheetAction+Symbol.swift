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
    handler: (@MainActor () -> Void)? = nil
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
      handler: handler
    )
  }
}
