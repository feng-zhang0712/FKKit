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
  public var style: FKBaseViewController.NavigationBarStyle = .system {
    didSet {
      guard let navigationController = activeNavigationController else { return }
      applyStyle(on: navigationController)
    }
  }
  public var prefersLargeTitlesWhileVisible: Bool?

  private var snapshot: FKNavigationChromeSnapshot?
  /// Set while the host is in a navigation stack so mutating ``style`` can re-apply without waiting for the next `viewWillAppear`.
  private weak var activeNavigationController: UINavigationController?

  public init() {}

  public func viewWillAppear(on viewController: UIViewController, animated: Bool) {
    guard let navigationController = viewController.navigationController else {
      activeNavigationController = nil
      return
    }
    activeNavigationController = navigationController
    if snapshot == nil {
      let bar = navigationController.navigationBar
      snapshot = FKNavigationChromeSnapshot(
        wasNavigationBarHidden: navigationController.isNavigationBarHidden,
        standardAppearance: FKCompositeNavigationChromeAppearanceCopying.copied(bar.standardAppearance),
        scrollEdgeAppearance: FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(bar.scrollEdgeAppearance),
        compactAppearance: FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(bar.compactAppearance),
        compactScrollEdgeAppearance: FKCompositeNavigationChromeAppearanceCopying
          .copiedCompactScrollEdgeIfPresent(from: bar),
        prefersLargeTitles: bar.prefersLargeTitles,
        isTranslucent: bar.isTranslucent
      )
    }
    navigationController.setNavigationBarHidden(visibility == .hidden, animated: animated)
    if let prefersLargeTitlesWhileVisible {
      navigationController.navigationBar.prefersLargeTitles = prefersLargeTitlesWhileVisible
    }
    applyStyle(on: navigationController)
  }

  public func viewWillDisappear(on viewController: UIViewController, animated: Bool) {
    activeNavigationController = nil
    guard isLeavingHierarchyPermanently(viewController) else { return }
    restoreIfNeeded(on: viewController, animated: animated)
  }

  private func applyStyle(on navigationController: UINavigationController) {
    let bar = navigationController.navigationBar
    switch style {
    case .system:
      guard let snapshot else { return }
      bar.standardAppearance = FKCompositeNavigationChromeAppearanceCopying.copied(snapshot.standardAppearance)
      bar.scrollEdgeAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(
        snapshot.scrollEdgeAppearance
      )
      bar.compactAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(snapshot.compactAppearance)
      if #available(iOS 15.0, *) {
        bar.compactScrollEdgeAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(
          snapshot.compactScrollEdgeAppearance
        )
      }
      bar.isTranslucent = snapshot.isTranslucent
    case .opaqueDefault:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithDefaultBackground()
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
      if #available(iOS 15.0, *) {
        bar.compactScrollEdgeAppearance = appearance
      }
      bar.isTranslucent = false
    case .transparent:
      let appearance = UINavigationBarAppearance()
      appearance.configureWithTransparentBackground()
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
      if #available(iOS 15.0, *) {
        bar.compactScrollEdgeAppearance = appearance
      }
      bar.isTranslucent = true
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
      bar.standardAppearance = appearance
      bar.scrollEdgeAppearance = appearance
      bar.compactAppearance = appearance
      if #available(iOS 15.0, *) {
        bar.compactScrollEdgeAppearance = appearance
      }
      bar.isTranslucent = true
    }
  }

  private func restoreIfNeeded(on viewController: UIViewController, animated: Bool) {
    guard let snapshot, let navigationController = viewController.navigationController else { return }
    let bar = navigationController.navigationBar
    navigationController.setNavigationBarHidden(snapshot.wasNavigationBarHidden, animated: animated)
    bar.standardAppearance = FKCompositeNavigationChromeAppearanceCopying.copied(snapshot.standardAppearance)
    bar.scrollEdgeAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(
      snapshot.scrollEdgeAppearance
    )
    bar.compactAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(snapshot.compactAppearance)
    if #available(iOS 15.0, *) {
      bar.compactScrollEdgeAppearance = FKCompositeNavigationChromeAppearanceCopying.copiedIfPresent(
        snapshot.compactScrollEdgeAppearance
      )
    }
    bar.prefersLargeTitles = snapshot.prefersLargeTitles
    bar.isTranslucent = snapshot.isTranslucent
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
  private var capturedContentPopBeforeAppearance: Bool?

  public init() {}

  public func viewWillAppear(on viewController: UIViewController) {
    guard let navigationController = viewController.navigationController else { return }
    capturedBeforeAppearance = navigationController.interactivePopGestureRecognizer?.isEnabled
    if #available(iOS 26.0, *) {
      capturedContentPopBeforeAppearance =
        navigationController.interactiveContentPopGestureRecognizer?.isEnabled
    }
    let allow = !disablesInteractivePopGesture
    navigationController.interactivePopGestureRecognizer?.isEnabled = allow
    if #available(iOS 26.0, *) {
      navigationController.interactiveContentPopGestureRecognizer?.isEnabled = allow
    }
  }

  public func viewWillDisappear(on viewController: UIViewController) {
    guard isLeavingHierarchyPermanently(viewController) else { return }
    if let navigationController = viewController.navigationController {
      if let capturedBeforeAppearance {
        navigationController.interactivePopGestureRecognizer?.isEnabled = capturedBeforeAppearance
      }
      if #available(iOS 26.0, *) {
        if let capturedContentPopBeforeAppearance {
          navigationController.interactiveContentPopGestureRecognizer?.isEnabled =
            capturedContentPopBeforeAppearance
        }
      }
    }
    capturedBeforeAppearance = nil
    capturedContentPopBeforeAppearance = nil
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

private enum FKCompositeNavigationChromeAppearanceCopying {
  static func copied(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
    guard let copy = appearance.copy() as? UINavigationBarAppearance else { return appearance }
    return copy
  }

  static func copiedIfPresent(_ appearance: UINavigationBarAppearance?) -> UINavigationBarAppearance? {
    guard let appearance else { return nil }
    return copied(appearance)
  }

  static func copiedCompactScrollEdgeIfPresent(from bar: UINavigationBar) -> UINavigationBarAppearance? {
    if #available(iOS 15.0, *) {
      return copiedIfPresent(bar.compactScrollEdgeAppearance)
    }
    return nil
  }
}

private struct FKNavigationChromeSnapshot {
  let wasNavigationBarHidden: Bool
  let standardAppearance: UINavigationBarAppearance
  let scrollEdgeAppearance: UINavigationBarAppearance?
  let compactAppearance: UINavigationBarAppearance?
  let compactScrollEdgeAppearance: UINavigationBarAppearance?
  let prefersLargeTitles: Bool
  let isTranslucent: Bool
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
