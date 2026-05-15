import FKCoreKit
import FKUIKit
import UIKit

/// A lightweight `UIViewController` base that centralizes common UIKit patterns:
/// lifecycle entry points, optional state overlays, keyboard forwarding, navigation chrome
/// snapshot/restore, and analytics-friendly hooks without hard-wiring a specific architecture.
@MainActor
open class FKBaseViewController: UIViewController {

  // MARK: - Public types

  /// Visibility of the navigation bar while this view controller is visible.
  public enum NavigationBarVisibility {
    case visible
    case hidden
  }

  /// Navigation bar chrome applied while this view controller is visible.
  ///
  /// Custom styles (``opaqueDefault``, ``transparent``, ``gradient``) apply to this controller’s
  /// ``UINavigationItem`` so `UINavigationController` can interpolate during interactive transitions.
  ///
  /// ``system`` clears those per-item overrides and restores the navigation **bar** from the snapshot
  /// captured on this controller’s first ``viewWillAppear`` (deep-copied appearances, translucency,
  /// and compact scroll-edge when available). When no snapshot exists, ``system`` only clears the item
  /// overrides.
  public enum NavigationBarStyle {
    case system
    case opaqueDefault
    case transparent
    case gradient(
      colors: [UIColor],
      locations: [NSNumber]? = nil,
      startPoint: CGPoint = CGPoint(x: 0.0, y: 0.0),
      endPoint: CGPoint = CGPoint(x: 1.0, y: 0.0)
    )
  }

  // MARK: - Public configuration

  /// When `true`, taps outside of the first responder dismiss the keyboard.
  public var dismissKeyboardOnTapEnabled: Bool = true {
    didSet { updateTapToDismissGestureState() }
  }

  /// When `true`, recursively disables vertical/horizontal bounce on scroll views in `view`'s subtree.
  public var disableScrollViewBounceByDefault: Bool = true

  /// When `true`, disables the navigation controller's interactive pop gesture while this controller is visible.
  ///
  /// On recent iOS releases, toggling `interactivePopGestureRecognizer.isEnabled` alone is not always honored.
  /// From iOS 26, ``UINavigationController/interactiveContentPopGestureRecognizer`` also drives interactive pops and
  /// must be toggled together with ``UINavigationController/interactivePopGestureRecognizer``.
  /// ``FKBaseViewController`` installs a one-time gesture delegate on the parent ``UINavigationController`` that
  /// consults the top ``FKBaseViewController`` and returns `false` from `gestureRecognizerShouldBegin` while
  /// this flag is `true`, forwarding other cases to UIKit’s original delegate. On iOS 26+, the same policy is
  /// applied to ``UINavigationController/interactiveContentPopGestureRecognizer`` in addition to
  /// ``UINavigationController/interactivePopGestureRecognizer``.
  public var disablesInteractivePopGesture: Bool = false {
    didSet {
      applyInteractivePopGestureOnlyIfOnScreen()
    }
  }

  /// Navigation bar visibility while this controller is on-screen (restored when leaving).
  public var navigationBarVisibility: NavigationBarVisibility = .visible {
    didSet {
      reapplyNavigationChromeIfOnScreen()
    }
  }

  /// Navigation bar appearance while this controller is on-screen (restored when leaving).
  public var navigationBarStyle: NavigationBarStyle = .system {
    didSet {
      reapplyNavigationChromeIfOnScreen()
    }
  }

  /// Preferred status bar style for this controller.
  public var preferredStatusBarAppearance: UIStatusBarStyle = .default {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
      navigationController?.setNeedsStatusBarAppearanceUpdate()
    }
  }

  /// When `false`, keyboard notifications are not observed.
  public var keyboardObservationEnabled: Bool = true

  /// When non-nil, assigns `UINavigationBar.prefersLargeTitles` while visible (restored when leaving).
  public var prefersLargeTitlesWhileVisible: Bool? {
    didSet {
      reapplyNavigationChromeIfOnScreen()
    }
  }

  /// Optional hook for analytics or diagnostics without coupling to a concrete SDK.
  public var logHandler: (@MainActor (String, [String: String]) -> Void)?

  /// When `true`, forwards lifecycle markers to ``FKLogger`` at the `.debug` level (in addition to ``logHandler``).
  public var debugLifecycleLoggingEnabled: Bool = false

  // MARK: - Public state

  /// `true` after the first `viewDidAppear(_:)`.
  public private(set) var hasCompletedInitialAppearance: Bool = false

  /// `true` between `viewDidAppear` and `viewWillDisappear`.
  public private(set) var isViewAppeared: Bool = false

  // MARK: - Private UI

  private let loadingView = UIActivityIndicatorView(style: .large)
  private let emptyStateView = FKBaseStateView()
  private let errorStateView = FKBaseStateView()
  private var keyboardObservers: [NSObjectProtocol] = []
  private lazy var tapToDismissGesture: UITapGestureRecognizer = {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismissKeyboard))
    gesture.cancelsTouchesInView = false
    return gesture
  }()

  private var hasPerformedBaseSetup = false

  /// Captures navigation chrome before this controller mutates it; restored in `viewWillDisappear`.
  private var navigationChromeSnapshot: NavigationChromeSnapshot?

  /// `interactivePopGestureRecognizer.isEnabled` (and on iOS 26+ `interactiveContentPopGestureRecognizer.isEnabled`)
  /// immediately before this controller last applied ``disablesInteractivePopGesture`` in `viewWillAppear`.
  private var interactivePopGestureCapturedBeforeAppearance: Bool?
  private var interactiveContentPopGestureCapturedBeforeAppearance: Bool?

  // MARK: - Init

  public init() {
    super.init(nibName: nil, bundle: nil)
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: - Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    performBaseSetupIfNeeded()
    setupUI()
    setupConstraints()
    setupBindings()
    applyDefaultScrollBouncePolicyIfNeeded()
    logLifecycleEvent("viewDidLoad")
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let navigationController {
      FKNavigationInteractivePopGestureInstaller.installIfNeeded(on: navigationController)
    }
    captureNavigationChromeSnapshotIfNeeded()
    applyNavigationConfiguration(animated: animated)
    updateInteractivePopGestureForCurrentAppearance()
    logLifecycleEvent("viewWillAppear")
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    isViewAppeared = true
    if !hasCompletedInitialAppearance {
      hasCompletedInitialAppearance = true
      loadInitialContent()
      viewDidAppearForTheFirstTime(animated)
    }
    startKeyboardObservationIfNeeded()
    synchronizeInteractivePopGestureAfterNavigationChromeChange()
    logLifecycleEvent("viewDidAppear")
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopKeyboardObservationIfNeeded()
    if isLeavingHierarchyPermanently {
      restoreNavigationChromeIfNeeded(animated: animated)
      restoreInteractivePopGestureIfNeeded()
    }
    logLifecycleEvent("viewWillDisappear")
  }

  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    isViewAppeared = false
    logLifecycleEvent("viewDidDisappear")
  }

  open override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    view.setNeedsLayout()
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    traitCollectionDidChangeHandling(previousTraitCollection)
  }

  // MARK: - Overridable entry points

  /// Builds the view hierarchy. Prefer lightweight work here; defer heavy I/O to async layers.
  open func setupUI() {}

  /// Activates layout constraints for views created in ``setupUI()``.
  open func setupConstraints() {}

  /// Binds view models, user actions, and subscriptions.
  open func setupBindings() {}

  /// Called exactly once on the first `viewDidAppear(_:)`, **before** ``viewDidAppearForTheFirstTime(_:)``.
  ///
  /// Override to kick off first-page loads or subscriptions. Prefer async work; do not block the main thread.
  open func loadInitialContent() {}

  /// Called once after the first `viewDidAppear(_:)`, immediately after ``loadInitialContent()``.
  ///
  /// Use for UI that must run only after the view is on-screen (e.g. intro animations).
  open func viewDidAppearForTheFirstTime(_ animated: Bool) {}

  /// Keyboard frame updates (parsed on the main queue).
  open func keyboardWillChange(to frame: CGRect, duration: TimeInterval, curve: UIView.AnimationCurve) {}

  /// Keyboard will hide (parsed on the main queue).
  open func keyboardWillHide(duration: TimeInterval, curve: UIView.AnimationCurve) {}

  /// Supported orientations for this controller.
  open var allowedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }

  /// Preferred orientation when this controller is first presented.
  open var preferredInitialOrientation: UIInterfaceOrientation {
    .portrait
  }

  /// Respond to dynamic type, dark mode, and other trait changes.
  open func traitCollectionDidChangeHandling(_ previousTraitCollection: UITraitCollection?) {}

  open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    allowedInterfaceOrientations
  }

  open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    preferredInitialOrientation
  }

  open override var preferredStatusBarStyle: UIStatusBarStyle {
    preferredStatusBarAppearance
  }

  // MARK: - Public UI helpers

  /// Shows the loading indicator and hides empty/error overlays.
  public func showLoading() {
    hideEmptyView()
    hideErrorView()
    loadingView.startAnimating()
    loadingView.isHidden = false
  }

  /// Hides the loading indicator.
  public func hideLoading() {
    loadingView.stopAnimating()
    loadingView.isHidden = true
  }

  /// Shows a full-screen empty state overlay.
  public func showEmptyView(message: String = "No content available.") {
    hideLoading()
    hideErrorView()
    emptyStateView.messageLabel.text = message
    emptyStateView.isHidden = false
  }

  /// Hides the empty state overlay.
  public func hideEmptyView() {
    emptyStateView.isHidden = true
  }

  /// Shows a full-screen error overlay with an optional retry action.
  public func showErrorView(
    message: String = "Something went wrong.",
    retryTitle: String? = nil,
    retryHandler: (@MainActor () -> Void)? = nil
  ) {
    hideLoading()
    hideEmptyView()
    errorStateView.messageLabel.text = message
    errorStateView.button.setTitle(retryTitle, for: .normal)
    errorStateView.actionHandler = retryHandler
    errorStateView.button.isHidden = (retryTitle == nil || retryHandler == nil)
    errorStateView.isHidden = false
  }

  /// Hides the error overlay.
  public func hideErrorView() {
    errorStateView.isHidden = true
    errorStateView.actionHandler = nil
  }

  /// Presents a short banner using ``FKToast`` defaults.
  public func showToast(_ message: String) {
    FKToast.show(message)
  }

  /// Installs a custom back button on the left navigation item.
  public func configureBackButton(image: UIImage? = nil, title: String? = nil, tintColor: UIColor? = nil) {
    let button = UIButton(type: .system)
    let symbolImage = image ?? UIImage(systemName: "chevron.backward")
    button.setImage(symbolImage, for: .normal)
    button.setTitle(title, for: .normal)
    button.tintColor = tintColor ?? view.tintColor
    button.setTitleColor(tintColor ?? view.tintColor, for: .normal)
    button.contentEdgeInsets = UIConstants.backButtonContentInsets
    button.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
  }

  /// Ends editing for the entire `view` subtree.
  public func dismissKeyboard() {
    view.endEditing(true)
  }

  // MARK: - Private setup

  private func performBaseSetupIfNeeded() {
    guard !hasPerformedBaseSetup else { return }
    hasPerformedBaseSetup = true

    view.backgroundColor = .systemBackground
    setupLoadingView()
    setupStateViews()
    updateTapToDismissGestureState()
  }

  private func setupLoadingView() {
    loadingView.translatesAutoresizingMaskIntoConstraints = false
    loadingView.hidesWhenStopped = true
    loadingView.isHidden = true
    view.addSubview(loadingView)
    NSLayoutConstraint.activate([
      loadingView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
      loadingView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
    ])
  }

  private func setupStateViews() {
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    emptyStateView.isHidden = true
    view.addSubview(emptyStateView)

    errorStateView.translatesAutoresizingMaskIntoConstraints = false
    errorStateView.isHidden = true
    view.addSubview(errorStateView)

    NSLayoutConstraint.activate([
      emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      errorStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      errorStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      errorStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      errorStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  private func applyDefaultScrollBouncePolicyIfNeeded() {
    guard disableScrollViewBounceByDefault else { return }
    view.fk_applyBounce(enabled: false)
  }

  /// `true` when this controller is popped, dismissed, or removed from its parent (not when another controller is pushed on top).
  private var isLeavingHierarchyPermanently: Bool {
    isBeingDismissed || isMovingFromParent
  }

  private func captureNavigationChromeSnapshotIfNeeded() {
    guard navigationChromeSnapshot == nil, let navigationController else { return }
    let bar = navigationController.navigationBar
    navigationChromeSnapshot = NavigationChromeSnapshot(
      wasNavigationBarHidden: navigationController.isNavigationBarHidden,
      standardAppearance: Self.copiedNavigationBarAppearance(bar.standardAppearance),
      scrollEdgeAppearance: Self.copiedNavigationBarAppearanceIfPresent(bar.scrollEdgeAppearance),
      compactAppearance: Self.copiedNavigationBarAppearanceIfPresent(bar.compactAppearance),
      compactScrollEdgeAppearance: Self.copiedCompactScrollEdgeAppearanceIfPresent(bar),
      prefersLargeTitles: bar.prefersLargeTitles,
      isTranslucent: bar.isTranslucent
    )
  }

  private func restoreNavigationChromeIfNeeded(animated: Bool) {
    guard let snapshot = navigationChromeSnapshot, let navigationController else { return }
    let bar = navigationController.navigationBar
    navigationController.setNavigationBarHidden(snapshot.wasNavigationBarHidden, animated: animated)
    bar.standardAppearance = Self.copiedNavigationBarAppearance(snapshot.standardAppearance)
    bar.scrollEdgeAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.scrollEdgeAppearance)
    bar.compactAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.compactAppearance)
    if #available(iOS 15.0, *) {
      bar.compactScrollEdgeAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.compactScrollEdgeAppearance)
    }
    bar.prefersLargeTitles = snapshot.prefersLargeTitles
    bar.isTranslucent = snapshot.isTranslucent
    navigationChromeSnapshot = nil
  }

  private func applyNavigationConfiguration(animated: Bool) {
    guard let navigationController else { return }
    navigationController.setNavigationBarHidden(navigationBarVisibility == .hidden, animated: animated)
    if let prefersLargeTitlesWhileVisible {
      navigationController.navigationBar.prefersLargeTitles = prefersLargeTitlesWhileVisible
    } else if let snapshot = navigationChromeSnapshot {
      navigationController.navigationBar.prefersLargeTitles = snapshot.prefersLargeTitles
    }
    applyNavigationBarStyle()
    setNeedsStatusBarAppearanceUpdate()
    navigationController.setNeedsStatusBarAppearanceUpdate()
    synchronizeInteractivePopGestureAfterNavigationChromeChange()
  }

  /// Re-applies navigation chrome when public flags change while this controller is already on-screen.
  private func reapplyNavigationChromeIfOnScreen() {
    guard isViewAppeared, navigationController != nil, viewIfLoaded?.window != nil else { return }
    applyNavigationConfiguration(animated: true)
  }

  /// Updates only the pop gesture when ``disablesInteractivePopGesture`` toggles at runtime (without touching the snapshot).
  private func applyInteractivePopGestureOnlyIfOnScreen() {
    guard isViewAppeared, let navigationController, viewIfLoaded?.window != nil else { return }
    applyInteractivePopGesturesAllowingPop(!disablesInteractivePopGesture, on: navigationController)
  }

  private func applyNavigationBarStyle() {
    guard let navigationController else { return }
    let bar = navigationController.navigationBar
    switch navigationBarStyle {
    case .system:
      clearPerViewControllerNavigationItemAppearances()
      guard let snapshot = navigationChromeSnapshot else { return }
      bar.standardAppearance = Self.copiedNavigationBarAppearance(snapshot.standardAppearance)
      bar.scrollEdgeAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.scrollEdgeAppearance)
      bar.compactAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.compactAppearance)
      if #available(iOS 15.0, *) {
        bar.compactScrollEdgeAppearance = Self.copiedNavigationBarAppearanceIfPresent(snapshot.compactScrollEdgeAppearance)
      }
      bar.isTranslucent = snapshot.isTranslucent
    case .opaqueDefault:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithDefaultBackground()
      applySharedNavigationBarChrome(bar: bar, item: navigationItem, appearance: appearance, translucent: false)
    case .transparent:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      applySharedNavigationBarChrome(bar: bar, item: navigationItem, appearance: appearance, translucent: true)
    case let .gradient(colors, locations, startPoint, endPoint):
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      appearance.backgroundImage = FKGradientImageFactory.makeGradientImage(
        colors: colors,
        locations: locations,
        size: UIConstants.navigationBarGradientSize,
        startPoint: startPoint,
        endPoint: endPoint
      )
      applySharedNavigationBarChrome(bar: bar, item: navigationItem, appearance: appearance, translucent: true)
    }
  }

  /// Per-`UINavigationItem` chrome lets `UINavigationController` interpolate styles during interactive pops.
  /// Bar-level `isTranslucent` still follows the active style because UIKit has no per-item translucency flag.
  private func applySharedNavigationBarChrome(
    bar: UINavigationBar,
    item: UINavigationItem,
    appearance: UINavigationBarAppearance,
    translucent: Bool
  ) {
    item.standardAppearance = appearance
    item.scrollEdgeAppearance = appearance
    item.compactAppearance = appearance
    if #available(iOS 15.0, *) {
      item.compactScrollEdgeAppearance = appearance
    }
    bar.isTranslucent = translucent
  }

  private func clearPerViewControllerNavigationItemAppearances() {
    navigationItem.standardAppearance = nil
    navigationItem.scrollEdgeAppearance = nil
    navigationItem.compactAppearance = nil
    if #available(iOS 15.0, *) {
      navigationItem.compactScrollEdgeAppearance = nil
    }
  }

  /// `setNavigationBarHidden` can reset the pop gesture after layout; re-sync once the transition has settled.
  private func synchronizeInteractivePopGestureAfterNavigationChromeChange() {
    guard let navigationController, viewIfLoaded?.window != nil else { return }
    applyInteractivePopGesturesAllowingPop(!disablesInteractivePopGesture, on: navigationController)
  }

  /// Applies ``disablesInteractivePopGesture`` to both edge and (iOS 26+) content interactive pop recognizers.
  private func applyInteractivePopGesturesAllowingPop(_ allow: Bool, on navigationController: UINavigationController) {
    navigationController.interactivePopGestureRecognizer?.isEnabled = allow
    if #available(iOS 26.0, *) {
      navigationController.interactiveContentPopGestureRecognizer?.isEnabled = allow
    }
  }

  private static func copiedNavigationBarAppearance(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
    guard let copy = appearance.copy() as? UINavigationBarAppearance else {
      return appearance
    }
    return copy
  }

  private static func copiedNavigationBarAppearanceIfPresent(_ appearance: UINavigationBarAppearance?) -> UINavigationBarAppearance? {
    guard let appearance else { return nil }
    return copiedNavigationBarAppearance(appearance)
  }

  private static func copiedCompactScrollEdgeAppearanceIfPresent(_ bar: UINavigationBar) -> UINavigationBarAppearance? {
    if #available(iOS 15.0, *) {
      return copiedNavigationBarAppearanceIfPresent(bar.compactScrollEdgeAppearance)
    }
    return nil
  }

  private func updateInteractivePopGestureForCurrentAppearance() {
    guard let navigationController else { return }
    interactivePopGestureCapturedBeforeAppearance = navigationController.interactivePopGestureRecognizer?.isEnabled
    if #available(iOS 26.0, *) {
      interactiveContentPopGestureCapturedBeforeAppearance =
        navigationController.interactiveContentPopGestureRecognizer?.isEnabled
    }
    applyInteractivePopGesturesAllowingPop(!disablesInteractivePopGesture, on: navigationController)
  }

  private func restoreInteractivePopGestureIfNeeded() {
    guard let navigationController else { return }
    if let interactivePopGestureCapturedBeforeAppearance {
      navigationController.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureCapturedBeforeAppearance
    }
    if #available(iOS 26.0, *) {
      if let interactiveContentPopGestureCapturedBeforeAppearance {
        navigationController.interactiveContentPopGestureRecognizer?.isEnabled =
          interactiveContentPopGestureCapturedBeforeAppearance
      }
    }
    interactivePopGestureCapturedBeforeAppearance = nil
    interactiveContentPopGestureCapturedBeforeAppearance = nil
  }

  private func updateTapToDismissGestureState() {
    if dismissKeyboardOnTapEnabled {
      if tapToDismissGesture.view == nil {
        view.addGestureRecognizer(tapToDismissGesture)
      }
    } else if tapToDismissGesture.view != nil {
      view.removeGestureRecognizer(tapToDismissGesture)
    }
  }

  // MARK: - Keyboard

  private func startKeyboardObservationIfNeeded() {
    guard keyboardObservationEnabled, keyboardObservers.isEmpty else { return }

    let center = NotificationCenter.default
    let willChange = center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard
        let self,
        let userInfo = notification.userInfo,
        let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
      else {
        return
      }
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
        ?? UIView.AnimationCurve.easeInOut.rawValue
      let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
      self.keyboardWillChange(to: frame, duration: duration, curve: curve)
    }

    let willHide = center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self else { return }
      let userInfo = notification.userInfo
      let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
        ?? UIView.AnimationCurve.easeInOut.rawValue
      let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
      self.keyboardWillHide(duration: duration, curve: curve)
    }

    keyboardObservers = [willChange, willHide]
  }

  private func stopKeyboardObservationIfNeeded() {
    guard !keyboardObservers.isEmpty else { return }
    let center = NotificationCenter.default
    keyboardObservers.forEach(center.removeObserver)
    keyboardObservers.removeAll()
  }

  private func logLifecycleEvent(_ event: String) {
    let metadata: [String: String] = ["controller": String(describing: type(of: self))]
    logHandler?(event, metadata)
    if debugLifecycleLoggingEnabled {
      FKLogger.shared.debug("FKBaseViewController.\(event)", metadata: metadata)
    }
  }

  // MARK: - Actions

  @objc private func handleTapToDismissKeyboard() {
    dismissKeyboard()
  }

  @objc private func handleBackButtonTapped() {
    if let navigationController, navigationController.viewControllers.first != self {
      navigationController.popViewController(animated: true)
    } else {
      dismiss(animated: true)
    }
  }
}

// MARK: - Interactive pop (gesture delegate)

/// Installs a forwarding `UIGestureRecognizerDelegate` once per `UINavigationController` so
/// ``FKBaseViewController/disablesInteractivePopGesture`` is enforced even when `isEnabled` is reset by UIKit.
/// On iOS 26+, the same delegate is attached to ``UINavigationController/interactiveContentPopGestureRecognizer``.
@MainActor
private enum FKNavigationInteractivePopGestureInstaller {
  private static let installs = NSMapTable<AnyObject, AnyObject>(
    keyOptions: .weakMemory,
    valueOptions: .strongMemory
  )

  static func installIfNeeded(on navigationController: UINavigationController) {
    guard let pop = navigationController.interactivePopGestureRecognizer else { return }
    if installs.object(forKey: navigationController) != nil { return }
    if pop.delegate is FKNavigationInteractivePopGestureDelegate { return }

    var originalContentPopDelegate: UIGestureRecognizerDelegate?
    if #available(iOS 26.0, *) {
      originalContentPopDelegate =
        navigationController.interactiveContentPopGestureRecognizer?.delegate as? UIGestureRecognizerDelegate
    }

    let interceptor = FKNavigationInteractivePopGestureDelegate(
      navigationController: navigationController,
      originalPopGestureDelegate: pop.delegate as? UIGestureRecognizerDelegate,
      originalContentPopGestureDelegate: originalContentPopDelegate
    )
    pop.delegate = interceptor
    if #available(iOS 26.0, *) {
      navigationController.interactiveContentPopGestureRecognizer?.delegate = interceptor
    }
    installs.setObject(interceptor, forKey: navigationController)
  }
}

@MainActor
private final class FKNavigationInteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
  weak var navigationController: UINavigationController?
  weak var originalPopGestureDelegate: UIGestureRecognizerDelegate?
  weak var originalContentPopGestureDelegate: UIGestureRecognizerDelegate?

  init(
    navigationController: UINavigationController,
    originalPopGestureDelegate: UIGestureRecognizerDelegate?,
    originalContentPopGestureDelegate: UIGestureRecognizerDelegate?
  ) {
    self.navigationController = navigationController
    self.originalPopGestureDelegate = originalPopGestureDelegate
    self.originalContentPopGestureDelegate = originalContentPopGestureDelegate
    super.init()
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let nc = navigationController else { return false }
    if let top = nc.topViewController as? FKBaseViewController, top.disablesInteractivePopGesture {
      return false
    }

    if gestureRecognizer === nc.interactivePopGestureRecognizer {
      if let originalPopGestureDelegate {
        return originalPopGestureDelegate.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
      }
      return nc.viewControllers.count > 1
    }

    if #available(iOS 26.0, *) {
      if gestureRecognizer === nc.interactiveContentPopGestureRecognizer {
        if let originalContentPopGestureDelegate {
          return originalContentPopGestureDelegate.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
        }
        return nc.viewControllers.count > 1
      }
    }

    return true
  }
}

// MARK: - Navigation snapshot

private struct NavigationChromeSnapshot {
  let wasNavigationBarHidden: Bool
  let standardAppearance: UINavigationBarAppearance
  let scrollEdgeAppearance: UINavigationBarAppearance?
  let compactAppearance: UINavigationBarAppearance?
  let compactScrollEdgeAppearance: UINavigationBarAppearance?
  let prefersLargeTitles: Bool
  let isTranslucent: Bool
}

// MARK: - Internal constants & helpers

private enum UIConstants {
  static let navigationBarGradientSize = CGSize(width: 4.0, height: 88.0)
  static let stateViewHorizontalInset: CGFloat = 32.0
  static let stateViewSpacing: CGFloat = 12.0
  static let stateButtonTopSpacing: CGFloat = 8.0
  static let backButtonContentInsets = UIEdgeInsets(top: 4.0, left: 0.0, bottom: 4.0, right: 0.0)
}

private final class FKBaseStateView: UIView {
  let stackView = UIStackView()
  let messageLabel = UILabel()
  let button = UIButton(type: .system)
  var actionHandler: (@MainActor () -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  private func setupUI() {
    backgroundColor = .clear

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = UIConstants.stateViewSpacing
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)

    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.textColor = .secondaryLabel
    messageLabel.font = .preferredFont(forTextStyle: .body)
    messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

    button.addTarget(self, action: #selector(handleButtonTapped), for: .touchUpInside)
    button.isHidden = true

    stackView.addArrangedSubview(messageLabel)
    stackView.addArrangedSubview(button)
    stackView.setCustomSpacing(UIConstants.stateButtonTopSpacing, after: messageLabel)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UIConstants.stateViewHorizontalInset),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UIConstants.stateViewHorizontalInset),
    ])
  }

  @objc private func handleButtonTapped() {
    actionHandler?()
  }
}

private enum FKGradientImageFactory {
  static func makeGradientImage(
    colors: [UIColor],
    locations: [NSNumber]?,
    size: CGSize,
    startPoint: CGPoint,
    endPoint: CGPoint
  ) -> UIImage? {
    guard size.width > 0.0, size.height > 0.0, !colors.isEmpty else { return nil }

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let layer = CAGradientLayer()
      layer.frame = CGRect(origin: .zero, size: size)
      layer.colors = colors.map(\.cgColor)
      layer.locations = locations
      layer.startPoint = startPoint
      layer.endPoint = endPoint
      layer.render(in: context.cgContext)
    }
  }
}

private extension UIView {
  func fk_applyBounce(enabled: Bool) {
    if let scrollView = self as? UIScrollView {
      scrollView.bounces = enabled
      scrollView.alwaysBounceVertical = enabled
      scrollView.alwaysBounceHorizontal = enabled
    }
    subviews.forEach { $0.fk_applyBounce(enabled: enabled) }
  }
}
