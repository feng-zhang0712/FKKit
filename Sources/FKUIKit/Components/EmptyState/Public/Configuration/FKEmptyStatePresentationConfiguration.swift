import Foundation

/// Loading-phase visibility rules for ``FKEmptyStateView``.
public struct FKEmptyStateLoadingBehavior: Equatable, Sendable {
  /// Hides the image slot entirely during loading.
  public var hidesImage: Bool
  /// Suppresses description text during loading when you want spinner + title only.
  public var hidesDescription: Bool
  /// Skips loading overlay while pull-to-refresh runs (`UIRefreshControl` or ``UIScrollView/fk_pullToRefresh``).
  public var skipsWhileRefreshing: Bool

  public init(
    hidesImage: Bool = true,
    hidesDescription: Bool = false,
    skipsWhileRefreshing: Bool = true
  ) {
    self.hidesImage = hidesImage
    self.hidesDescription = hidesDescription
    self.skipsWhileRefreshing = skipsWhileRefreshing
  }
}

/// Overlay behavior, animation, and accessibility announcements.
public struct FKEmptyStatePresentationConfiguration {
  /// Animation applied when ``FKEmptyStateView/apply(_:animated:)`` updates content (`animated == true`).
  public var transition: FKEmptyStateTransition
  /// Fade duration for `UIView` transitions and extension-driven show/hide animations.
  public var fadeDuration: TimeInterval
  /// When `false`, `UIScrollView` scrolling is disabled while the overlay is visible.
  public var keepScrollEnabled: Bool
  /// Enables `fk_refreshEmptyStateAutomatically` behavior on `UIScrollView`.
  public var automaticallyShowsWhenContentFits: Bool
  /// When `true`, background taps trigger `endEditing(true)` (search fields, etc.).
  public var supportsTapToDismissKeyboard: Bool
  /// Pins content above the keyboard using `keyboardLayoutGuide` when `true`.
  public var adjustsPositionForKeyboard: Bool
  /// Accessibility / announcement behavior for state changes.
  public var announcesStateChanges: Bool
  /// Loading-phase visibility and refresh interaction rules.
  public var loadingBehavior: FKEmptyStateLoadingBehavior

  public init(
    transition: FKEmptyStateTransition = .none,
    fadeDuration: TimeInterval = 0.25,
    keepScrollEnabled: Bool = true,
    automaticallyShowsWhenContentFits: Bool = false,
    supportsTapToDismissKeyboard: Bool = true,
    adjustsPositionForKeyboard: Bool = true,
    announcesStateChanges: Bool = true,
    loadingBehavior: FKEmptyStateLoadingBehavior = FKEmptyStateLoadingBehavior()
  ) {
    self.transition = transition
    self.fadeDuration = max(0, fadeDuration)
    self.keepScrollEnabled = keepScrollEnabled
    self.automaticallyShowsWhenContentFits = automaticallyShowsWhenContentFits
    self.supportsTapToDismissKeyboard = supportsTapToDismissKeyboard
    self.adjustsPositionForKeyboard = adjustsPositionForKeyboard
    self.announcesStateChanges = announcesStateChanges
    self.loadingBehavior = loadingBehavior
  }
}
