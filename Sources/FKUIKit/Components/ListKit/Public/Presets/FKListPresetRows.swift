import Foundation

// MARK: - Accessory

/// UITableView-style accessory indicators for preset rows.
public enum FKListAccessory: Hashable, Sendable {
  case none
  case disclosureIndicator
  case checkmark
  case customView(id: String)
}

// MARK: - Leading content

/// Leading image content for icon-style preset rows.
public enum FKListLeadingContent: Hashable, Sendable {
  /// Local asset or bundle image name.
  case asset(name: String)
  /// SF Symbol name.
  case symbol(name: String)
  /// Remote image URL; rendered with ``FKImageView`` when available.
  case remoteURL(URL)
}

// MARK: - Row models

/// Single-line text row.
public struct FKListTextRow: Hashable, Sendable {
  public var title: String
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(title: String, isEnabled: Bool = true, isSelectable: Bool = true) {
    self.title = title
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

/// Title + subtitle row.
public struct FKListSubtitleRow: Hashable, Sendable {
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(
    title: String,
    subtitle: String? = nil,
    isEnabled: Bool = true,
    isSelectable: Bool = true
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

/// Leading icon + title row.
public struct FKListIconRow: Hashable, Sendable {
  public var leading: FKListLeadingContent
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(
    leading: FKListLeadingContent,
    title: String,
    subtitle: String? = nil,
    isEnabled: Bool = true,
    isSelectable: Bool = true
  ) {
    self.leading = leading
    self.title = title
    self.subtitle = subtitle
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

/// Title row with trailing switch; handler id registered in ``FKListSwitchHandlerRegistry``.
public struct FKListSwitchRow: Hashable, Sendable {
  public var leading: FKListLeadingContent?
  public var title: String
  public var subtitle: String?
  public var isOn: Bool
  public var handlerID: String
  public var isEnabled: Bool

  public init(
    leading: FKListLeadingContent? = nil,
    title: String,
    subtitle: String? = nil,
    isOn: Bool,
    handlerID: String,
    isEnabled: Bool = true
  ) {
    self.leading = leading
    self.title = title
    self.subtitle = subtitle
    self.isOn = isOn
    self.handlerID = handlerID
    self.isEnabled = isEnabled
  }
}

/// Title row with trailing checkbox; handler id registered in ``FKListCheckboxHandlerRegistry``.
public struct FKListCheckboxRow: Hashable, Sendable {
  public var leading: FKListLeadingContent?
  public var title: String
  public var subtitle: String?
  public var isChecked: Bool
  public var handlerID: String
  public var isEnabled: Bool

  public init(
    leading: FKListLeadingContent? = nil,
    title: String,
    subtitle: String? = nil,
    isChecked: Bool,
    handlerID: String,
    isEnabled: Bool = true
  ) {
    self.leading = leading
    self.title = title
    self.subtitle = subtitle
    self.isChecked = isChecked
    self.handlerID = handlerID
    self.isEnabled = isEnabled
  }
}

/// Settings-style disclosure row.
public struct FKListDisclosureRow: Hashable, Sendable {
  public var leading: FKListLeadingContent?
  public var title: String
  public var subtitle: String?
  public var accessory: FKListAccessory
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(
    leading: FKListLeadingContent? = nil,
    title: String,
    subtitle: String? = nil,
    accessory: FKListAccessory = .disclosureIndicator,
    isEnabled: Bool = true,
    isSelectable: Bool = true
  ) {
    self.leading = leading
    self.title = title
    self.subtitle = subtitle
    self.accessory = accessory
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

/// Title row with trailing value label.
public struct FKListValueRow: Hashable, Sendable {
  public var leading: FKListLeadingContent?
  public var title: String
  public var subtitle: String?
  public var value: String
  public var isEnabled: Bool
  public var isSelectable: Bool

  public init(
    leading: FKListLeadingContent? = nil,
    title: String,
    subtitle: String? = nil,
    value: String,
    isEnabled: Bool = true,
    isSelectable: Bool = true
  ) {
    self.leading = leading
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.isEnabled = isEnabled
    self.isSelectable = isSelectable
  }
}

// MARK: - Preset item

/// Built-in row presets rendered by ``FKListPresetTableCell`` / collection equivalents.
public enum FKListPresetItem: Hashable, Sendable {
  case text(FKListTextRow)
  case subtitle(FKListSubtitleRow)
  case icon(FKListIconRow)
  case `switch`(FKListSwitchRow)
  case checkbox(FKListCheckboxRow)
  case disclosure(FKListDisclosureRow)
  case customValue(FKListValueRow)
}
