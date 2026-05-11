import UIKit

// MARK: - Composite façade

/// Bundles optional UIKit cross-cutting behaviors so plain `UIViewController` subclasses can use
/// **composition** instead of inheriting ``FKBaseViewController``.
///
/// Forward UIKit lifecycle callbacks with ``forward(_:for:)`` from your controller.
@MainActor
public final class FKViewControllerComposite {

  /// Keyboard frame notifications (started in `viewDidAppear`, stopped in `viewWillDisappear`).
  public let keyboard = FKCompositeKeyboardObservation()

  /// Navigation bar visibility, style, and large-title preference with snapshot restore.
  public let navigationChrome = FKCompositeNavigationChrome()

  /// Toggles `interactivePopGestureRecognizer` while visible, restoring when detached.
  public let interactivePopGesture = FKCompositeInteractivePopGesture()

  /// Tap outside controls to end editing.
  public let tapToDismissKeyboard = FKCompositeTapToDismissKeyboard()

  /// `isViewAppeared` / `hasCompletedInitialAppearance` tracking.
  public let appearanceState = FKViewControllerAppearanceState()

  /// When `true`, recursively disables scroll view bounce under the host `view` during `viewDidLoad`.
  public var disablesScrollBounceRecursivelyByDefault: Bool = false

  public init() {}

  /// Forwards a UIKit lifecycle event to the composed services.
  public func forward(_ lifecycle: FKViewControllerCompositeLifecycle, for viewController: UIViewController) {
    switch lifecycle {
    case .viewDidLoad:
      if disablesScrollBounceRecursivelyByDefault {
        FKCompositeScrollBounce.applyRecursively(to: viewController.view, enabled: false)
      }
      tapToDismissKeyboard.bindIfNeeded(to: viewController)

    case let .viewWillAppear(animated):
      navigationChrome.viewWillAppear(on: viewController, animated: animated)
      interactivePopGesture.viewWillAppear(on: viewController)

    case let .viewDidAppear(animated):
      appearanceState.onViewDidAppear(animated: animated)
      keyboard.startIfNeeded()

    case let .viewWillDisappear(animated):
      keyboard.stop()
      navigationChrome.viewWillDisappear(on: viewController, animated: animated)
      interactivePopGesture.viewWillDisappear(on: viewController)

    case .viewDidDisappear:
      appearanceState.onViewDidDisappear()
    }
  }
}

// MARK: - Appearance state

/// Tracks simple visibility flags for controllers using the composition bucket.
@MainActor
public final class FKViewControllerAppearanceState {
  /// `true` after the first `viewDidAppear`.
  public private(set) var hasCompletedInitialAppearance = false

  /// `true` between `viewDidAppear` and `viewWillDisappear`.
  public private(set) var isViewAppeared = false

  /// Optional callback invoked once after the first `viewDidAppear`.
  public var onFirstAppearance: (@MainActor (Bool) -> Void)?

  fileprivate func onViewDidAppear(animated: Bool) {
    isViewAppeared = true
    if !hasCompletedInitialAppearance {
      hasCompletedInitialAppearance = true
      onFirstAppearance?(animated)
    }
  }

  fileprivate func onViewDidDisappear() {
    isViewAppeared = false
  }
}

// MARK: - Keyboard

/// Observes keyboard notifications and forwards parsed animation metadata.
@MainActor
public final class FKCompositeKeyboardObservation {
  /// When `false`, ``startIfNeeded()`` becomes a no-op.
  public var isEnabled: Bool = true

  public var onWillChangeFrame: (@MainActor (CGRect, TimeInterval, UIView.AnimationCurve) -> Void)?
  public var onWillHide: (@MainActor (TimeInterval, UIView.AnimationCurve) -> Void)?

  private var observers: [NSObjectProtocol] = []

  public init() {}

  public func startIfNeeded() {
    guard isEnabled, observers.isEmpty else { return }
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
      else { return }
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
        ?? UIView.AnimationCurve.easeInOut.rawValue
      let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
      self.onWillChangeFrame?(frame, duration, curve)
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
      self.onWillHide?(duration, curve)
    }

    observers = [willChange, willHide]
  }

  public func stop() {
    guard !observers.isEmpty else { return }
    let center = NotificationCenter.default
    observers.forEach(center.removeObserver)
    observers.removeAll()
  }
}

// MARK: - Navigation chrome

/// Mirrors ``FKBaseViewController`` navigation bar snapshot rules: capture on first `viewWillAppear`,
/// restore only when the host is permanently removed (pop / dismiss / detach).
@MainActor
public final class FKCompositeNavigationChrome {
  public var visibility: FKBaseViewController.NavigationBarVisibility = .visible
  public var style: FKBaseViewController.NavigationBarStyle = .system
  public var prefersLargeTitlesWhileVisible: Bool?

  private var snapshot: FKNavigationChromeSnapshot?

  public init() {}

  public func viewWillAppear(on viewController: UIViewController, animated: Bool) {
    guard let navigationController = viewController.navigationController else { return }
    if snapshot == nil {
      let bar = navigationController.navigationBar
      snapshot = FKNavigationChromeSnapshot(
        wasNavigationBarHidden: navigationController.isNavigationBarHidden,
        standardAppearance: bar.standardAppearance,
        scrollEdgeAppearance: bar.scrollEdgeAppearance,
        compactAppearance: bar.compactAppearance,
        prefersLargeTitles: bar.prefersLargeTitles
      )
    }
    navigationController.setNavigationBarHidden(visibility == .hidden, animated: animated)
    if let prefersLargeTitlesWhileVisible {
      navigationController.navigationBar.prefersLargeTitles = prefersLargeTitlesWhileVisible
    }
    applyStyle(on: navigationController)
  }

  public func viewWillDisappear(on viewController: UIViewController, animated: Bool) {
    guard isLeavingHierarchyPermanently(viewController) else { return }
    restoreIfNeeded(on: viewController, animated: animated)
  }

  private func applyStyle(on navigationController: UINavigationController) {
    switch style {
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
      appearance.backgroundImage = FKCompositionGradientImage.make(
        colors: colors,
        locations: locations,
        size: FKCompositionUIConstants.navigationBarGradientSize,
        startPoint: startPoint,
        endPoint: endPoint
      )
      let bar = navigationController.navigationBar
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
    }
  }

  private func restoreIfNeeded(on viewController: UIViewController, animated: Bool) {
    guard let snapshot, let navigationController = viewController.navigationController else { return }
    let bar = navigationController.navigationBar
    navigationController.setNavigationBarHidden(snapshot.wasNavigationBarHidden, animated: animated)
    bar.standardAppearance = snapshot.standardAppearance
    bar.scrollEdgeAppearance = snapshot.scrollEdgeAppearance
    bar.compactAppearance = snapshot.compactAppearance
    bar.prefersLargeTitles = snapshot.prefersLargeTitles
    self.snapshot = nil
  }

  private func isLeavingHierarchyPermanently(_ viewController: UIViewController) -> Bool {
    viewController.isBeingDismissed || viewController.isMovingFromParent
  }
}

// MARK: - Interactive pop

@MainActor
public final class FKCompositeInteractivePopGesture {
  public var disablesInteractivePopGesture: Bool = false

  private var capturedBeforeAppearance: Bool?

  public init() {}

  public func viewWillAppear(on viewController: UIViewController) {
    guard viewController.navigationController != nil else { return }
    capturedBeforeAppearance = viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled
    viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = !disablesInteractivePopGesture
  }

  public func viewWillDisappear(on viewController: UIViewController) {
    guard isLeavingHierarchyPermanently(viewController) else { return }
    if let capturedBeforeAppearance, let navigationController = viewController.navigationController {
      navigationController.interactivePopGestureRecognizer?.isEnabled = capturedBeforeAppearance
    }
    capturedBeforeAppearance = nil
  }

  private func isLeavingHierarchyPermanently(_ viewController: UIViewController) -> Bool {
    viewController.isBeingDismissed || viewController.isMovingFromParent
  }
}

// MARK: - Tap to dismiss keyboard

@MainActor
public final class FKCompositeTapToDismissKeyboard: NSObject {
  public var isEnabled: Bool = true {
    didSet { updateGestureAttachment() }
  }

  private weak var host: UIViewController?
  private var didBind = false
  private lazy var gesture: UITapGestureRecognizer = {
    let g = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    g.cancelsTouchesInView = false
    return g
  }()

  public override init() {
    super.init()
  }

  /// Installs the gesture on `viewController.view` once per composite instance.
  public func bindIfNeeded(to viewController: UIViewController) {
    guard !didBind else { return }
    didBind = true
    host = viewController
    updateGestureAttachment()
  }

  @objc private func handleTap() {
    host?.view.endEditing(true)
  }

  private func updateGestureAttachment() {
    guard let view = host?.view, didBind else { return }
    if isEnabled {
      if gesture.view == nil {
        view.addGestureRecognizer(gesture)
      }
    } else if gesture.view != nil {
      view.removeGestureRecognizer(gesture)
    }
  }
}

// MARK: - Scroll bounce

public enum FKCompositeScrollBounce {
  public static func applyRecursively(to root: UIView, enabled: Bool) {
    if let scroll = root as? UIScrollView {
      scroll.bounces = enabled
      scroll.alwaysBounceVertical = enabled
      scroll.alwaysBounceHorizontal = enabled
    }
    root.subviews.forEach { applyRecursively(to: $0, enabled: enabled) }
  }
}

// MARK: - Private types

private struct FKNavigationChromeSnapshot {
  let wasNavigationBarHidden: Bool
  let standardAppearance: UINavigationBarAppearance
  let scrollEdgeAppearance: UINavigationBarAppearance?
  let compactAppearance: UINavigationBarAppearance?
  let prefersLargeTitles: Bool
}

private enum FKCompositionUIConstants {
  static let navigationBarGradientSize = CGSize(width: 4.0, height: 88.0)
}

private enum FKCompositionGradientImage {
  static func make(
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
