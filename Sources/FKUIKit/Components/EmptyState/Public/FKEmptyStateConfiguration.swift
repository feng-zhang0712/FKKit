import UIKit

// MARK: - Custom accessory placement

/// Positions `customAccessoryView` (e.g. Lottie) relative to the image slot and text stack.
public enum FKEmptyStateCustomPlacement: Equatable, Sendable {
  /// Shows only the custom view in the illustration row (built-in image hidden).
  case replaceImage
  /// Custom view above `UIImageView`.
  case aboveImage
  /// Custom view between image and title.
  case belowImage
  /// Custom view after description, before spinner/button slot (spinner only in loading phase).
  case belowDescription
}

// MARK: - Content alignment

/// Vertical placement strategy for the placeholder content inside the host view.
public enum FKEmptyStateContentAlignment: Equatable, Sendable {
  /// Centers content vertically in the safe area.
  case center
  /// Pins content to the top safe area with a configurable offset.
  case top
}

// MARK: - Preset scenarios

/// High-level product scenarios used by `FKEmptyStateConfiguration.scenario(_:)` to pre-fill copy and `FKEmptyStatePhase`.
///
/// Localize strings in your app before shipping.
public enum FKEmptyStateScenario: CaseIterable, Sendable {
  /// Offline or transport failure messaging; primary action reloads.
  case noNetwork
  /// Search returned nothing.
  case noSearchResult
  /// Favorites / wishlist empty.
  case noFavorites
  /// Order history empty.
  case noOrders
  /// Inbox / notifications empty.
  case noMessages
  /// Request failed; uses `phase == .error` and mandatory retry styling.
  case loadFailed
  /// Authorization / feature gate.
  case noPermission
  /// Account required.
  case notLoggedIn
}

// MARK: - Button style

/// Visual style for the primary action button (filled configuration on iOS 15+).
public struct FKEmptyStateButtonStyle {
  /// Button title; `nil` hides the button unless `phase == .error` (retry is forced).
  public var title: String?
  /// Foreground (text) color.
  public var titleColor: UIColor
  /// Title font (also applied where configuration supports it).
  public var font: UIFont
  /// Fill color for filled button style.
  public var backgroundColor: UIColor
  /// Corner radius applied through `UIButton.Configuration` background (iOS 15+).
  public var cornerRadius: CGFloat
  /// Padding inside the button around the title.
  public var contentInsets: UIEdgeInsets
  /// Optional stroke; `nil` means no border.
  public var borderColor: UIColor?
  /// Hairline width when `borderColor` is set.
  public var borderWidth: CGFloat

  public init(
    title: String? = nil,
    titleColor: UIColor = .white,
    font: UIFont = .systemFont(ofSize: 15, weight: .semibold),
    backgroundColor: UIColor = .systemBlue,
    cornerRadius: CGFloat = 10,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0
  ) {
    self.title = title
    self.titleColor = titleColor
    self.font = font
    self.backgroundColor = backgroundColor
    self.cornerRadius = cornerRadius
    self.contentInsets = contentInsets
    self.borderColor = borderColor
    self.borderWidth = borderWidth
  }
}

// MARK: - Model

/// Immutable-friendly configuration struct for `FKEmptyStateView`; use fluent helpers (`withTitle`, etc.) to derive copies.
public struct FKEmptyStateConfiguration {
  /// Controls which layout branch runs inside `FKEmptyStateView` (loading vs empty/error vs hidden).
  public var phase: FKEmptyStatePhase

  /// High-level semantic type used by i18n presets and state resolution helpers.
  ///
  /// This is intentionally separate from `phase`:
  /// - `phase` controls the rendering pipeline (loading vs non-loading vs hidden).
  /// - `type` communicates intent (offline, noResults, permissionDenied, etc.).
  public var type: FKEmptyStateType

  /// Screen context for presets and layout decisions.
  public var context: FKEmptyStateLayoutContext

  /// Density preset used to derive spacing/layout defaults (does not override explicit values).
  public var density: FKEmptyStateDensity

  /// Stack direction for content blocks (vertical/horizontal). Loading phase always uses vertical layout.
  public var axis: FKEmptyStateAxis

  /// Main illustration; hidden when `isImageHidden` or `nil` (unless `customAccessoryView` replaces it).
  public var image: UIImage?
  /// Applied to the built-in `UIImageView` (`scaleAspectFit` by default).
  public var imageContentMode: UIView.ContentMode
  /// When set, the illustration is rendered as a template image with this tint (useful for SF Symbols).
  public var imageTintColor: UIColor?
  /// VoiceOver label for the illustration; when `nil` the image is not an accessibility element.
  public var imageAccessibilityLabel: String?
  /// Primary headline for empty/error; also fallback text for loading if `loadingMessage` is `nil`.
  public var title: String?
  /// Secondary body copy (empty/error; optional during loading via `hidesDescriptionForLoadingPhase`).
  public var description: String?
  /// Preferred loading subtitle; when `nil` and `phase == .loading`, `title` is shown under the spinner.
  public var loadingMessage: String?
  /// Primary button look-and-feel.
  public var buttonStyle: FKEmptyStateButtonStyle
  /// Optional override for the secondary (bordered) action; `nil` derives a bordered variant from ``buttonStyle``.
  public var secondaryButtonStyle: FKEmptyStateButtonStyle?
  /// Optional override for the tertiary / plain action; `nil` derives a plain variant from ``buttonStyle``.
  public var tertiaryButtonStyle: FKEmptyStateButtonStyle?

  /// Optional multi-action set; when not empty it supersedes the legacy single button slot.
  ///
  /// - Important: UIKit rendering maps `primary` → filled button, `secondary` → bordered button,
  ///   `tertiary` → plain button. Override chrome via ``secondaryButtonStyle`` / ``tertiaryButtonStyle``.
  ///   Action events are emitted by id.
  public var actions: FKEmptyStateActionSet

  /// Hides the image view even when `image` is non-nil.
  public var isImageHidden: Bool
  /// Hides the title label.
  public var isTitleHidden: Bool
  /// Hides the description label.
  public var isDescriptionHidden: Bool
  /// Hides the action button (ignored for `phase == .error`, which always shows retry).
  public var isButtonHidden: Bool

  /// Optional slots for advanced composition. When set, these views are inserted into the stack.
  /// Slots are never force-sized by the library; callers own intrinsic size or constraints inside the slot view.
  public var headerSlot: UIView?
  public var mediaSlot: UIView?
  public var contentSlot: UIView?
  public var actionsSlot: UIView?
  public var footerSlot: UIView?

  /// Accessibility / announcement behavior for state changes.
  public var announcesStateChanges: Bool

  public var titleColor: UIColor
  public var descriptionColor: UIColor
  public var titleFont: UIFont
  public var descriptionFont: UIFont
  public var textAlignment: NSTextAlignment
  /// Fixed image dimensions when set; intrinsic sizing otherwise.
  public var imageSize: CGSize?

  /// Vertical spacing between stack subviews.
  public var verticalSpacing: CGFloat
  /// Padding around the content column; applied via `directionalLayoutMargins` and `layoutMarginsGuide` constraints.
  public var contentInsets: UIEdgeInsets
  /// Max width of the centered content column.
  public var maxContentWidth: CGFloat
  /// Vertical content alignment in the host view.
  public var contentAlignment: FKEmptyStateContentAlignment
  /// Additional Y offset for the content container (positive = lower, negative = higher).
  public var verticalOffset: CGFloat
  /// Root view background behind gradient/dimming (defaults to opaque system color).
  public var backgroundColor: UIColor
  /// When non-empty, draws a `CAGradientLayer` under subviews.
  public var gradientColors: [UIColor]
  /// Unit gradient start (0…1).
  public var gradientStartPoint: CGPoint
  /// Unit gradient end (0…1).
  public var gradientEndPoint: CGPoint

  /// Extra black dimming alpha on `blockingDimmingView` (0 = invisible dimmer).
  public var blockingOverlayAlpha: CGFloat

  /// When `true`, background taps trigger `endEditing(true)` (search fields, etc.).
  public var supportsTapToDismissKeyboard: Bool
  /// Fade duration for `UIView` transitions and extension-driven show/hide animations.
  public var fadeDuration: TimeInterval
  /// Animation applied when ``FKEmptyStateView/apply(_:animated:)`` updates content (`animated == true`).
  public var transition: FKEmptyStateTransition
  /// When `false`, `UIScrollView` scrolling is disabled while the overlay is visible.
  public var keepScrollEnabled: Bool
  /// Enables `fk_refreshEmptyStateAutomatically` behavior on `UIScrollView`.
  public var automaticallyShowsWhenContentFits: Bool

  /// Tint for `UIActivityIndicatorView` in loading phase.
  public var loadingTintColor: UIColor
  /// Spinner size (`.medium` / `.large`, etc.).
  public var activityIndicatorStyle: UIActivityIndicatorView.Style

  /// Hides the image slot entirely during loading.
  public var hidesImageForLoadingPhase: Bool
  /// Suppresses description text during loading when you want spinner + title only.
  public var hidesDescriptionForLoadingPhase: Bool

  /// Skips loading overlay while pull-to-refresh runs (`UIRefreshControl` or ``UIScrollView/fk_pullToRefresh``).
  public var skipsLoadingWhileRefreshing: Bool

  /// Pins content above the keyboard using `keyboardLayoutGuide` when `true`.
  public var adjustsPositionForKeyboard: Bool

  /// Optional custom view (e.g. Lottie); placement follows `customAccessoryPlacement`.
  public var customAccessoryView: UIView?
  public var customAccessoryPlacement: FKEmptyStateCustomPlacement

  /// Overrides layout direction for RTL testing or forced direction UI. `nil` follows system.
  public var forcedLayoutDirection: UIUserInterfaceLayoutDirection?

  public init(
    phase: FKEmptyStatePhase = .empty,
    type: FKEmptyStateType = .empty,
    context: FKEmptyStateLayoutContext = .section,
    density: FKEmptyStateDensity = .regular,
    axis: FKEmptyStateAxis = .vertical,
    image: UIImage? = nil,
    imageContentMode: UIView.ContentMode = .scaleAspectFit,
    imageTintColor: UIColor? = nil,
    imageAccessibilityLabel: String? = nil,
    title: String? = nil,
    description: String? = nil,
    loadingMessage: String? = nil,
    buttonStyle: FKEmptyStateButtonStyle = FKEmptyStateButtonStyle(),
    secondaryButtonStyle: FKEmptyStateButtonStyle? = nil,
    tertiaryButtonStyle: FKEmptyStateButtonStyle? = nil,
    actions: FKEmptyStateActionSet = FKEmptyStateActionSet(),
    isImageHidden: Bool = false,
    isTitleHidden: Bool = false,
    isDescriptionHidden: Bool = false,
    isButtonHidden: Bool = true,
    headerSlot: UIView? = nil,
    mediaSlot: UIView? = nil,
    contentSlot: UIView? = nil,
    actionsSlot: UIView? = nil,
    footerSlot: UIView? = nil,
    announcesStateChanges: Bool = true,
    titleColor: UIColor = .label,
    descriptionColor: UIColor = .secondaryLabel,
    titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold),
    descriptionFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
    textAlignment: NSTextAlignment = .center,
    imageSize: CGSize? = nil,
    verticalSpacing: CGFloat = 10,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20),
    maxContentWidth: CGFloat = 320,
    contentAlignment: FKEmptyStateContentAlignment = .center,
    verticalOffset: CGFloat = 0,
    /// Opaque by default so the overlay hides underlying scroll content in any orientation (set `.clear` only if you intentionally need a see-through layer).
    backgroundColor: UIColor = .systemBackground,
    gradientColors: [UIColor] = [],
    gradientStartPoint: CGPoint = CGPoint(x: 0.5, y: 0),
    gradientEndPoint: CGPoint = CGPoint(x: 0.5, y: 1),
    blockingOverlayAlpha: CGFloat = 0,
    supportsTapToDismissKeyboard: Bool = true,
    fadeDuration: TimeInterval = 0.25,
    transition: FKEmptyStateTransition = .none,
    keepScrollEnabled: Bool = true,
    automaticallyShowsWhenContentFits: Bool = false,
    loadingTintColor: UIColor = .secondaryLabel,
    activityIndicatorStyle: UIActivityIndicatorView.Style = .large,
    hidesImageForLoadingPhase: Bool = true,
    hidesDescriptionForLoadingPhase: Bool = false,
    skipsLoadingWhileRefreshing: Bool = true,
    adjustsPositionForKeyboard: Bool = true,
    customAccessoryView: UIView? = nil,
    customAccessoryPlacement: FKEmptyStateCustomPlacement = .belowImage,
    forcedLayoutDirection: UIUserInterfaceLayoutDirection? = nil
  ) {
    self.phase = phase
    self.type = type
    self.context = context
    self.density = density
    self.axis = axis
    self.image = image
    self.imageContentMode = imageContentMode
    self.imageTintColor = imageTintColor
    self.imageAccessibilityLabel = imageAccessibilityLabel
    self.title = title
    self.description = description
    self.loadingMessage = loadingMessage
    self.buttonStyle = buttonStyle
    self.secondaryButtonStyle = secondaryButtonStyle
    self.tertiaryButtonStyle = tertiaryButtonStyle
    self.actions = actions
    self.isImageHidden = isImageHidden
    self.isTitleHidden = isTitleHidden
    self.isDescriptionHidden = isDescriptionHidden
    self.isButtonHidden = isButtonHidden
    self.headerSlot = headerSlot
    self.mediaSlot = mediaSlot
    self.contentSlot = contentSlot
    self.actionsSlot = actionsSlot
    self.footerSlot = footerSlot
    self.announcesStateChanges = announcesStateChanges
    self.titleColor = titleColor
    self.descriptionColor = descriptionColor
    self.titleFont = titleFont
    self.descriptionFont = descriptionFont
    self.textAlignment = textAlignment
    self.imageSize = imageSize
    self.verticalSpacing = max(0, verticalSpacing)
    self.contentInsets = contentInsets
    self.maxContentWidth = max(180, maxContentWidth)
    self.contentAlignment = contentAlignment
    self.verticalOffset = verticalOffset
    self.backgroundColor = backgroundColor
    self.gradientColors = gradientColors
    self.gradientStartPoint = gradientStartPoint
    self.gradientEndPoint = gradientEndPoint
    self.blockingOverlayAlpha = min(1, max(0, blockingOverlayAlpha))
    self.supportsTapToDismissKeyboard = supportsTapToDismissKeyboard
    self.fadeDuration = max(0, fadeDuration)
    self.transition = transition
    self.keepScrollEnabled = keepScrollEnabled
    self.automaticallyShowsWhenContentFits = automaticallyShowsWhenContentFits
    self.loadingTintColor = loadingTintColor
    self.activityIndicatorStyle = activityIndicatorStyle
    self.hidesImageForLoadingPhase = hidesImageForLoadingPhase
    self.hidesDescriptionForLoadingPhase = hidesDescriptionForLoadingPhase
    self.skipsLoadingWhileRefreshing = skipsLoadingWhileRefreshing
    self.adjustsPositionForKeyboard = adjustsPositionForKeyboard
    self.customAccessoryView = customAccessoryView
    self.customAccessoryPlacement = customAccessoryPlacement
    self.forcedLayoutDirection = forcedLayoutDirection
  }
}

// MARK: - Factory & fluent helpers

public extension FKEmptyStateConfiguration {
  /// Default retry title when `phase == .error` and `buttonStyle.title` is empty.
  static var defaultRetryButtonTitle: String { FKUIKitI18n.string("fkuikit.empty.action.retry") }

  /// Returns a configuration pre-filled for `scenario`.
  static func scenario(_ scenario: FKEmptyStateScenario) -> FKEmptyStateConfiguration {
    switch scenario {
    case .noNetwork:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .offline,
        context: .section,
        image: scenarioImage("wifi.exclamationmark"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.no_network.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.no_network.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: FKUIKitI18n.string("fkuikit.empty.scenario.no_network.action")),
        isButtonHidden: false
      )
    case .noSearchResult:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .noResults,
        context: .search,
        image: scenarioImage("magnifyingglass"),
        title: FKUIKitI18n.string("fkuikit.empty.noResults.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.no_search.description"),
        isButtonHidden: true
      )
    case .noFavorites:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        context: .list,
        image: scenarioImage("heart.slash"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: FKUIKitI18n.string("fkuikit.empty.scenario.no_favorites.action")),
        isButtonHidden: false
      )
    case .noOrders:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        context: .list,
        image: scenarioImage("shippingbox"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: FKUIKitI18n.string("fkuikit.empty.scenario.no_orders.action")),
        isButtonHidden: false
      )
    case .noMessages:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .empty,
        context: .list,
        image: scenarioImage("tray.full"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.no_messages.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.no_messages.description"),
        isButtonHidden: true
      )
    case .loadFailed:
      return FKEmptyStateConfiguration(
        phase: .error,
        type: .error,
        context: .section,
        image: scenarioImage("exclamationmark.arrow.trianglehead.clockwise"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: defaultRetryButtonTitle),
        isButtonHidden: false
      )
    case .noPermission:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .permissionDenied,
        context: .section,
        image: scenarioImage("lock.shield"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.no_permission.title"),
        description: FKUIKitI18n.string("fkuikit.empty.permissionDenied.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: FKUIKitI18n.string("fkuikit.common.ok")),
        isButtonHidden: false
      )
    case .notLoggedIn:
      return FKEmptyStateConfiguration(
        phase: .empty,
        type: .newUser,
        context: .fullPage,
        image: scenarioImage("person.crop.circle.badge.exclamationmark"),
        title: FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.description"),
        buttonStyle: FKEmptyStateButtonStyle(title: FKUIKitI18n.string("fkuikit.empty.scenario.not_logged_in.action")),
        isButtonHidden: false
      )
    }
  }

  /// Builds a configuration from ``FKEmptyStateResolver`` output and optional input metadata.
  ///
  /// Returns `phase == .content` when the resolver yields `.none`. Error descriptions from
  /// ``FKEmptyStateInputs/errorDescription`` override the preset body copy for `.error`.
  static func resolved(from input: FKEmptyStateInputs) -> FKEmptyStateConfiguration {
    switch FKEmptyStateResolver.resolve(input) {
    case .none:
      return FKEmptyStateConfiguration(phase: .content)
    case let .show(type):
      return configuration(for: type, input: input)
    }
  }

  private static func scenarioImage(_ systemName: String) -> UIImage? {
    let configuration = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
    return UIImage(systemName: systemName, withConfiguration: configuration)
  }

  /// Returns the effective secondary button style (explicit override or derived from ``buttonStyle``).
  func resolvedSecondaryButtonStyle() -> FKEmptyStateButtonStyle {
    if let secondaryButtonStyle { return secondaryButtonStyle }
    return FKEmptyStateButtonStyle(
      title: nil,
      titleColor: buttonStyle.backgroundColor,
      font: buttonStyle.font,
      backgroundColor: .clear,
      cornerRadius: buttonStyle.cornerRadius,
      contentInsets: buttonStyle.contentInsets,
      borderColor: buttonStyle.backgroundColor,
      borderWidth: 1
    )
  }

  /// Returns the effective tertiary / link button style (explicit override or derived from ``buttonStyle``).
  func resolvedTertiaryButtonStyle() -> FKEmptyStateButtonStyle {
    if let tertiaryButtonStyle { return tertiaryButtonStyle }
    return FKEmptyStateButtonStyle(
      title: nil,
      titleColor: buttonStyle.backgroundColor,
      font: buttonStyle.font,
      backgroundColor: .clear,
      cornerRadius: 0,
      contentInsets: buttonStyle.contentInsets,
      borderColor: nil,
      borderWidth: 0
    )
  }

  private static func configuration(for type: FKEmptyStateType, input: FKEmptyStateInputs) -> FKEmptyStateConfiguration {
    switch type {
    case .offline:
      var config = scenario(.noNetwork)
      config.type = .offline
      return config
    case .noResults:
      var config = scenario(.noSearchResult)
      config.type = .noResults
      return config
    case .error:
      var config = scenario(.loadFailed)
      config.type = .error
      if let errorDescription = input.errorDescription, !errorDescription.isEmpty {
        config.description = errorDescription
      }
      return config
    case .permissionDenied:
      var config = scenario(.noPermission)
      config.type = .permissionDenied
      return config
    case .newUser:
      var config = scenario(.notLoggedIn)
      config.type = .newUser
      return config
    case .empty:
      return scenario(.noMessages)
    case .loading:
      return FKEmptyStateConfiguration(phase: .loading, type: .loading)
    case .notFound:
      var config = scenario(.noMessages)
      config.type = .notFound
      return config
    case .maintenance:
      var config = customState(
        identifier: "maintenance",
        title: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.title"),
        description: FKUIKitI18n.string("fkuikit.empty.scenario.load_failed.description"),
        buttonTitle: defaultRetryButtonTitle
      )
      config.type = .maintenance
      config.image = scenarioImage("wrench.and.screwdriver")
      config.isButtonHidden = false
      return config
    }
  }

  /// Returns a configuration for a custom business state identifier.
  ///
  /// - Parameters:
  ///   - identifier: Domain-specific key, such as `"maintenance"` or `"geo_restricted"`.
  ///   - title: Primary title.
  ///   - description: Secondary message.
  ///   - buttonTitle: Optional action title.
  static func customState(
    identifier: String,
    title: String?,
    description: String? = nil,
    buttonTitle: String? = nil
  ) -> FKEmptyStateConfiguration {
    FKEmptyStateConfiguration(
      phase: .custom(identifier),
      title: title,
      description: description,
      buttonStyle: FKEmptyStateButtonStyle(title: buttonTitle),
      isButtonHidden: buttonTitle == nil
    )
  }

  /// Returns a copy with `title` replaced.
  func withTitle(_ text: String?) -> Self {
    var copy = self
    copy.title = text
    return copy
  }

  /// Returns a copy with `description` replaced.
  func withDescription(_ text: String?) -> Self {
    var copy = self
    copy.description = text
    return copy
  }

  /// Returns a copy with `image` replaced.
  func withImage(_ image: UIImage?) -> Self {
    var copy = self
    copy.image = image
    return copy
  }

  /// Returns a copy with `imageTintColor` replaced.
  func withImageTintColor(_ color: UIColor?) -> Self {
    var copy = self
    copy.imageTintColor = color
    return copy
  }

  /// Returns a copy with `density` replaced.
  func withDensity(_ density: FKEmptyStateDensity) -> Self {
    var copy = self
    copy.density = density
    return copy
  }

  /// Returns a copy with `axis` replaced.
  func withAxis(_ axis: FKEmptyStateAxis) -> Self {
    var copy = self
    copy.axis = axis
    return copy
  }

  /// Returns a copy with `transition` replaced.
  func withTransition(_ transition: FKEmptyStateTransition) -> Self {
    var copy = self
    copy.transition = transition
    return copy
  }

  /// Returns a copy with `context` replaced.
  func withContext(_ context: FKEmptyStateLayoutContext) -> Self {
    var copy = self
    copy.context = context
    return copy
  }

  /// Returns a copy with `buttonStyle.title` set; hides the button when `text == nil` (except error phase enforcement in the view).
  func withButtonTitle(_ text: String?) -> Self {
    var copy = self
    copy.buttonStyle.title = text
    copy.isButtonHidden = (text == nil)
    return copy
  }

  /// Returns a copy with `phase` replaced.
  func withPhase(_ phase: FKEmptyStatePhase) -> Self {
    var copy = self
    copy.phase = phase
    return copy
  }

  /// Returns a copy with top/center alignment and vertical offset.
  func withLayout(alignment: FKEmptyStateContentAlignment, verticalOffset: CGFloat = 0) -> Self {
    var copy = self
    copy.contentAlignment = alignment
    copy.verticalOffset = verticalOffset
    return copy
  }
}

// MARK: - Global defaults (FKBadge-style)

/// Namespace for app-wide EmptyState defaults and future batch helpers.
///
/// Mirrors ``FKBadge`` + ``FKBadge/defaultConfiguration``; use ``defaultConfiguration`` as the baseline
/// for `UIView.fk_setEmptyState(…)` and copy-then-mutate flows at the screen level.
@MainActor
public enum FKEmptyState {
  /// Baseline typography, colors, and button style; override per screen after copying.
  public static var defaultConfiguration = FKEmptyStateConfiguration(
    buttonStyle: FKEmptyStateButtonStyle(
      title: nil,
      titleColor: .white,
      font: .systemFont(ofSize: 15, weight: .semibold),
      backgroundColor: .systemBlue,
      cornerRadius: 10
    ),
    titleColor: .label,
    descriptionColor: .secondaryLabel,
    backgroundColor: .systemBackground
  )

  /// Mutates a copy of ``defaultConfiguration`` and writes it back (typical app-launch branding setup).
  public static func configureDefault(_ body: (inout FKEmptyStateConfiguration) -> Void) {
    fk_emptyStateAssertMainThread()
    var copy = defaultConfiguration
    body(&copy)
    defaultConfiguration = copy
  }
}
