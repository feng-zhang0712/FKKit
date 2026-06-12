import UIKit

/// Embedded search field style presets for ``FKFormCellSearchCell`` (X-26–X-29).
public enum FKFormSearchCellStyle: Sendable, Equatable {
  /// Capsule inline filter (X-26).
  case capsule
  /// Rounded field with trailing search button (X-27).
  case roundedWithButton
  /// Leading category prefix chip (X-28).
  case prefixCategory(title: String)
  /// Trailing voice search icon (X-29).
  case withVoiceIcon
}

public extension FKFormSearchCellStyle {
  /// Maps a form search style to ``FKSearchFieldConfiguration`` presets.
  static func searchFieldConfiguration(for style: FKFormSearchCellStyle) -> FKSearchFieldConfiguration {
    switch style {
    case .capsule:
      return FKSearchFieldDefaults.compactFilter()
    case .roundedWithButton:
      var config = FKSearchFieldDefaults.compactFilter()
      config.appearance.cornerStyle = .fixed(10)
      return config
    case .prefixCategory:
      var config = FKSearchFieldDefaults.compactFilter()
      config.appearance.leadingIcon.image = UIImage(systemName: "line.3.horizontal.decrease")
      return config
    case .withVoiceIcon:
      var config = FKSearchFieldDefaults.compactFilter()
      config.appearance.leadingIcon.image = UIImage(systemName: "magnifyingglass")
      return config
    }
  }
}
