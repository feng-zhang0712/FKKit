import UIKit

/// Layout preset for search controls.
public enum FKSearchBarLayoutStyle: Sendable, Equatable {
  /// Expands when active; cancel appears on focus — typical `navigationItem.titleView` placement.
  case navigationBar
  /// Full-width rounded rect with fixed height — below navigation, above table content.
  case inlineCard
  /// Shorter height and tighter insets — toolbars and bottom sheets.
  case compactToolbar
  /// No outer chrome; optional underline — dense admin interfaces.
  case minimal
}

/// When the trailing clear control is visible.
public enum FKSearchClearButtonVisibility: Sendable, Equatable {
  /// First responder and non-empty text (default).
  case whileEditingNonEmpty
  /// Any time text is non-empty.
  case whileNonEmpty
  /// Hidden; host handles reset.
  case never
}

/// When the cancel control is visible (`FKSearchBar` only).
public enum FKSearchCancelButtonVisibility: Sendable, Equatable {
  /// Hidden until editing begins (default for navigation layout).
  case whileEditing
  /// Always visible when enabled in configuration.
  case always
  /// Hidden — inline/filter mode.
  case never
}

/// Action applied when the user taps cancel (`FKSearchBar` only).
public enum FKSearchCancelPolicy: Sendable, Equatable {
  /// Clear text and resign first responder (default navigation behavior).
  case clearAndResign
  /// Keep text and resign first responder.
  case resignOnly
  /// Restore text captured at `editingDidBegin` and resign.
  case revertAndResign
}

/// Text normalization applied before debounced emit and submit.
public enum FKSearchTextNormalization: Sendable, Equatable {
  case none
  case trimWhitespaceAndNewlines
  case collapseInternalWhitespace
  case maxLength(Int)
}

/// Loading indicator presentation mode.
public enum FKSearchLoadingPresentation: Sendable, Equatable {
  case none
  /// Small spinner trailing; may hide clear while loading.
  case activityIndicator
  /// Field disabled plus spinner.
  case disabledInput
}

/// Background material for search chrome.
public enum FKSearchBackgroundMaterial: Sendable, Equatable {
  case none
  case solid
  case blur(FKBlurConfiguration)
}

/// Corner treatment for search chrome.
public enum FKSearchCornerStyle: Sendable, Equatable {
  case none
  case fixed(CGFloat)
  case capsule
}

/// Optional border around search chrome.
public struct FKSearchBorderStyle: Sendable, Equatable {
  public var color: UIColor
  public var width: CGFloat

  public init(color: UIColor, width: CGFloat = 1) {
    self.color = color
    self.width = width
  }
}

/// Leading search icon configuration.
public struct FKSearchIconConfiguration: Sendable, Equatable {
  public var isHidden: Bool
  public var image: UIImage?
  public var pointSize: CGFloat

  public init(isHidden: Bool = false, image: UIImage? = nil, pointSize: CGFloat = 17) {
    self.isHidden = isHidden
    self.image = image
    self.pointSize = pointSize
  }
}

/// Typography and color for entered text.
public struct FKSearchTextStyle: @unchecked Sendable, Equatable {
  public var font: UIFont
  public var textColor: UIColor

  public init(font: UIFont = .preferredFont(forTextStyle: .body), textColor: UIColor = .label) {
    self.font = font
    self.textColor = textColor
  }
}

/// Typography and color for placeholder text.
public struct FKSearchPlaceholderStyle: @unchecked Sendable, Equatable {
  public var font: UIFont?
  public var textColor: UIColor

  public init(font: UIFont? = nil, textColor: UIColor = .placeholderText) {
    self.font = font
    self.textColor = textColor
  }
}

/// Cancel button title typography (`FKSearchBar` only).
public struct FKSearchCancelTitleStyle: @unchecked Sendable, Equatable {
  public var font: UIFont
  public var textColor: UIColor

  public init(font: UIFont = .preferredFont(forTextStyle: .body), textColor: UIColor = .systemBlue) {
    self.font = font
    self.textColor = textColor
  }
}

/// Per-state appearance overrides for search chrome.
public struct FKSearchBarStateAppearance: Sendable, Equatable {
  public var backgroundColor: UIColor?
  public var borderColor: UIColor?
  public var tintColor: UIColor?

  public init(
    backgroundColor: UIColor? = nil,
    borderColor: UIColor? = nil,
    tintColor: UIColor? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
    self.tintColor = tintColor
  }
}

/// Focused, normal, and disabled appearance overrides.
public struct FKSearchBarStateAppearances: Sendable, Equatable {
  public var normal: FKSearchBarStateAppearance
  public var focused: FKSearchBarStateAppearance
  public var disabled: FKSearchBarStateAppearance

  public init(
    normal: FKSearchBarStateAppearance = FKSearchBarStateAppearance(),
    focused: FKSearchBarStateAppearance = FKSearchBarStateAppearance(),
    disabled: FKSearchBarStateAppearance = FKSearchBarStateAppearance()
  ) {
    self.normal = normal
    self.focused = focused
    self.disabled = disabled
  }
}
