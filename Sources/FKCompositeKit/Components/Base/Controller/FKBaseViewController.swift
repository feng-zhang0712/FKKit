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
  /// ``system`` intentionally does **not** mutate `UINavigationBar` appearance so global
  /// styling from your app delegate or container remains intact. Use ``opaqueDefault`` when
  /// you need to reset to a standard opaque bar after a themed child screen.
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
  public var disablesInteractivePopGesture: Bool = false

  /// Navigation bar visibility while this controller is on-screen (restored when leaving).
  public var navigationBarVisibility: NavigationBarVisibility = .visible

  /// Navigation bar appearance while this controller is on-screen (restored when leaving).
  public var navigationBarStyle: NavigationBarStyle = .system

  /// Preferred status bar style for this controller.
  public var preferredStatusBarAppearance: UIStatusBarStyle = .default {
    didSet { setNeedsStatusBarAppearanceUpdate() }
  }

  /// When `false`, keyboard notifications are not observed.
  public var keyboardObservationEnabled: Bool = true

  /// When non-nil, assigns `UINavigationBar.prefersLargeTitles` while visible (restored when leaving).
  public var prefersLargeTitlesWhileVisible: Bool?

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

  /// `interactivePopGestureRecognizer.isEnabled` immediately before this controller last applied ``disablesInteractivePopGesture`` in `viewWillAppear`.
  private var interactivePopGestureCapturedBeforeAppearance: Bool?

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
      standardAppearance: bar.standardAppearance,
      scrollEdgeAppearance: bar.scrollEdgeAppearance,
      compactAppearance: bar.compactAppearance,
      prefersLargeTitles: bar.prefersLargeTitles
    )
  }

  private func restoreNavigationChromeIfNeeded(animated: Bool) {
    guard let snapshot = navigationChromeSnapshot, let navigationController else { return }
    let bar = navigationController.navigationBar
    navigationController.setNavigationBarHidden(snapshot.wasNavigationBarHidden, animated: animated)
    bar.standardAppearance = snapshot.standardAppearance
    bar.scrollEdgeAppearance = snapshot.scrollEdgeAppearance
    bar.compactAppearance = snapshot.compactAppearance
    bar.prefersLargeTitles = snapshot.prefersLargeTitles
    navigationChromeSnapshot = nil
  }

  private func applyNavigationConfiguration(animated: Bool) {
    guard let navigationController else { return }
    navigationController.setNavigationBarHidden(navigationBarVisibility == .hidden, animated: animated)
    if let prefersLargeTitlesWhileVisible {
      navigationController.navigationBar.prefersLargeTitles = prefersLargeTitlesWhileVisible
    }
    applyNavigationBarStyle()
  }

  private func applyNavigationBarStyle() {
    guard let navigationController else { return }
    switch navigationBarStyle {
    case .system:
      return
    case .opaqueDefault:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithDefaultBackground()
      let bar = navigationController.navigationBar
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
    case .transparent:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      let bar = navigationController.navigationBar
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
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
      let bar = navigationController.navigationBar
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
    }
  }

  private func updateInteractivePopGestureForCurrentAppearance() {
    guard navigationController != nil else { return }
    interactivePopGestureCapturedBeforeAppearance = navigationController?.interactivePopGestureRecognizer?.isEnabled
    navigationController?.interactivePopGestureRecognizer?.isEnabled = !disablesInteractivePopGesture
  }

  private func restoreInteractivePopGestureIfNeeded() {
    guard let navigationController else { return }
    if let interactivePopGestureCapturedBeforeAppearance {
      navigationController.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureCapturedBeforeAppearance
    }
    interactivePopGestureCapturedBeforeAppearance = nil
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

// MARK: - Navigation snapshot

private struct NavigationChromeSnapshot {
  let wasNavigationBarHidden: Bool
  let standardAppearance: UINavigationBarAppearance
  let scrollEdgeAppearance: UINavigationBarAppearance?
  let compactAppearance: UINavigationBarAppearance?
  let prefersLargeTitles: Bool
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
