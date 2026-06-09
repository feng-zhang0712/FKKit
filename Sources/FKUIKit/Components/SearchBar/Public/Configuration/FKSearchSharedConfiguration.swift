import UIKit

/// Layout metrics shared by ``FKSearchBar`` and ``FKSearchField``.
public struct FKSearchLayoutConfiguration: Sendable, Equatable {
  public var style: FKSearchBarLayoutStyle
  public var minimumHeight: CGFloat
  public var horizontalPadding: CGFloat
  public var iconSpacing: CGFloat
  public var growsWithDynamicType: Bool
  public var showsUnderline: Bool

  public init(
    style: FKSearchBarLayoutStyle = .inlineCard,
    minimumHeight: CGFloat = 44,
    horizontalPadding: CGFloat = 12,
    iconSpacing: CGFloat = 8,
    growsWithDynamicType: Bool = true,
    showsUnderline: Bool = false
  ) {
    self.style = style
    self.minimumHeight = minimumHeight
    self.horizontalPadding = horizontalPadding
    self.iconSpacing = iconSpacing
    self.growsWithDynamicType = growsWithDynamicType
    self.showsUnderline = showsUnderline
  }
}

/// Layered appearance for search chrome and typography.
public struct FKSearchAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var backgroundColor: UIColor
  public var backgroundMaterial: FKSearchBackgroundMaterial
  public var cornerStyle: FKSearchCornerStyle
  public var border: FKSearchBorderStyle?
  public var leadingIcon: FKSearchIconConfiguration
  public var textStyle: FKSearchTextStyle
  public var placeholderStyle: FKSearchPlaceholderStyle
  public var tintColor: UIColor
  public var cancelTitleStyle: FKSearchCancelTitleStyle
  public var stateAppearances: FKSearchBarStateAppearances

  public init(
    backgroundColor: UIColor = .secondarySystemBackground,
    backgroundMaterial: FKSearchBackgroundMaterial = .solid,
    cornerStyle: FKSearchCornerStyle = .capsule,
    border: FKSearchBorderStyle? = nil,
    leadingIcon: FKSearchIconConfiguration = FKSearchIconConfiguration(),
    textStyle: FKSearchTextStyle = FKSearchTextStyle(),
    placeholderStyle: FKSearchPlaceholderStyle = FKSearchPlaceholderStyle(),
    tintColor: UIColor = .secondaryLabel,
    cancelTitleStyle: FKSearchCancelTitleStyle = FKSearchCancelTitleStyle(),
    stateAppearances: FKSearchBarStateAppearances = FKSearchBarStateAppearances()
  ) {
    self.backgroundColor = backgroundColor
    self.backgroundMaterial = backgroundMaterial
    self.cornerStyle = cornerStyle
    self.border = border
    self.leadingIcon = leadingIcon
    self.textStyle = textStyle
    self.placeholderStyle = placeholderStyle
    self.tintColor = tintColor
    self.cancelTitleStyle = cancelTitleStyle
    self.stateAppearances = stateAppearances
  }
}

/// UITextField keyboard and autocorrection defaults tuned for search.
public struct FKSearchTextInputTraitsConfiguration: Sendable, Equatable {
  public var autocorrectionType: UITextAutocorrectionType
  public var autocapitalizationType: UITextAutocapitalizationType
  public var spellCheckingType: UITextSpellCheckingType
  public var smartQuotesType: UITextSmartQuotesType
  public var smartDashesType: UITextSmartDashesType
  public var returnKeyType: UIReturnKeyType
  public var keyboardType: UIKeyboardType
  public var textContentType: UITextContentType?
  public var normalization: FKSearchTextNormalization

  public init(
    autocorrectionType: UITextAutocorrectionType = .no,
    autocapitalizationType: UITextAutocapitalizationType = .none,
    spellCheckingType: UITextSpellCheckingType = .no,
    smartQuotesType: UITextSmartQuotesType = .no,
    smartDashesType: UITextSmartDashesType = .no,
    returnKeyType: UIReturnKeyType = .search,
    keyboardType: UIKeyboardType = .default,
    textContentType: UITextContentType? = nil,
    normalization: FKSearchTextNormalization = .trimWhitespaceAndNewlines
  ) {
    self.autocorrectionType = autocorrectionType
    self.autocapitalizationType = autocapitalizationType
    self.spellCheckingType = spellCheckingType
    self.smartQuotesType = smartQuotesType
    self.smartDashesType = smartDashesType
    self.returnKeyType = returnKeyType
    self.keyboardType = keyboardType
    self.textContentType = textContentType
    self.normalization = normalization
  }
}

/// Debounce settings for ``searchQueryChanged`` callbacks.
public struct FKSearchDebounceConfiguration: Sendable, Equatable {
  public var debounceInterval: TimeInterval
  public var isDebounceEnabled: Bool
  public var minimumQueryLengthForSearchCallback: Int
  public var flushDebounceOnClear: Bool

  public init(
    debounceInterval: TimeInterval = 0.35,
    isDebounceEnabled: Bool = true,
    minimumQueryLengthForSearchCallback: Int = 0,
    flushDebounceOnClear: Bool = true
  ) {
    self.debounceInterval = debounceInterval
    self.isDebounceEnabled = isDebounceEnabled
    self.minimumQueryLengthForSearchCallback = minimumQueryLengthForSearchCallback
    self.flushDebounceOnClear = flushDebounceOnClear
  }
}

/// Clear button visibility and interaction.
public struct FKSearchClearButtonConfiguration: @unchecked Sendable, Equatable {
  public var visibility: FKSearchClearButtonVisibility
  public var image: UIImage?
  public var accessibilityLabel: String
  public var clearResignsFirstResponder: Bool
  public var announcesClearToVoiceOver: Bool

  public init(
    visibility: FKSearchClearButtonVisibility = .whileEditingNonEmpty,
    image: UIImage? = nil,
    accessibilityLabel: String = FKUIKitI18n.string("fkuikit.search.clear_label"),
    clearResignsFirstResponder: Bool = false,
    announcesClearToVoiceOver: Bool = true
  ) {
    self.visibility = visibility
    self.image = image
    self.accessibilityLabel = accessibilityLabel
    self.clearResignsFirstResponder = clearResignsFirstResponder
    self.announcesClearToVoiceOver = announcesClearToVoiceOver
  }
}

/// Cancel button visibility and interaction (`FKSearchBar` only).
public struct FKSearchCancelButtonConfiguration: @unchecked Sendable, Equatable {
  public var visibility: FKSearchCancelButtonVisibility
  public var policy: FKSearchCancelPolicy
  public var title: String?
  public var accessibilityLabel: String
  public var animationDuration: TimeInterval

  public init(
    visibility: FKSearchCancelButtonVisibility = .whileEditing,
    policy: FKSearchCancelPolicy = .clearAndResign,
    title: String? = nil,
    accessibilityLabel: String = FKUIKitI18n.string("fkuikit.common.cancel"),
    animationDuration: TimeInterval = 0.25
  ) {
    self.visibility = visibility
    self.policy = policy
    self.title = title
    self.accessibilityLabel = accessibilityLabel
    self.animationDuration = animationDuration
  }
}

/// Loading indicator behavior during async search.
public struct FKSearchLoadingConfiguration: Sendable, Equatable {
  public var presentation: FKSearchLoadingPresentation
  public var hidesClearWhileLoading: Bool
  public var announcesLoadingToVoiceOver: Bool

  public init(
    presentation: FKSearchLoadingPresentation = .none,
    hidesClearWhileLoading: Bool = true,
    announcesLoadingToVoiceOver: Bool = false
  ) {
    self.presentation = presentation
    self.hidesClearWhileLoading = hidesClearWhileLoading
    self.announcesLoadingToVoiceOver = announcesLoadingToVoiceOver
  }
}

/// Return key submit behavior.
public struct FKSearchSubmitConfiguration: Sendable, Equatable {
  public var allowsEmptySubmit: Bool
  public var submitResignsFirstResponder: Bool

  public init(allowsEmptySubmit: Bool = false, submitResignsFirstResponder: Bool = false) {
    self.allowsEmptySubmit = allowsEmptySubmit
    self.submitResignsFirstResponder = submitResignsFirstResponder
  }
}

/// VoiceOver labels and hints for search controls.
public struct FKSearchAccessibilityConfiguration: Sendable, Equatable {
  public var textFieldLabel: String?
  public var textFieldHint: String?
  public var hidesDecorativeSearchIcon: Bool

  public init(
    textFieldLabel: String? = nil,
    textFieldHint: String? = nil,
    hidesDecorativeSearchIcon: Bool = true
  ) {
    self.textFieldLabel = textFieldLabel
    self.textFieldHint = textFieldHint
    self.hidesDecorativeSearchIcon = hidesDecorativeSearchIcon
  }
}
