import UIKit

/// HIG-style action sheet presented as a modal view controller (bottom, centered, or popover).
///
/// Create with ``init(configuration:)``, then call ``present(from:animated:completion:)`` or
/// ``present(from:anchoredTo:sourceRect:permittedArrowDirections:animated:completion:)`` for popovers.
@MainActor
public final class FKActionSheet: UIViewController {
  /// Latest configuration used to render rows.
  public private(set) var configuration: FKActionSheetConfiguration

  var onActionSelected: ((FKActionSheetAction, UUID?, Bool) -> Void)?
  var onToggleValueChanged: ((FKActionSheetAction, Bool) -> Void)?
  var onPanelLayoutChange: (() -> Void)?

  let panelView = UIView()

  weak var session: FKActionSheetSession?

  enum ConfigurationUpdateKind {
    case full
    case selectionOnly
    case singleAction(FKActionSheetAction)
  }

  let actionSheetView = FKActionSheetView()
  private let transitioningDelegateBox: FKActionSheetTransitioningDelegate
  private lazy var outsideTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))

  var panelHeightConstraint: NSLayoutConstraint?
  var panelWidthConstraint: NSLayoutConstraint?
  var panelCenterYConstraint: NSLayoutConstraint?
  var installedPanelLayout: InstalledPanelLayout?
  var installedLayoutConstraints: [NSLayoutConstraint] = []

  var lastResolvedPanelHeight: CGFloat = 0
  var lastLayoutWidth: CGFloat = 0
  var lastScrollEnabled: Bool?
  var hasScrolledToSelectionOnPresent = false
  var lastTableSafeBottom: CGFloat = -1
  var isUpdatingPanelLayout = false
  var presentationProgress: CGFloat = 1
  /// For ``FKActionSheetPresentationStyle/centered``, selects present (zoom from 1.08) vs dismiss (shrink to 0.92) scale curves.
  var centeredTransitionReveals = true
  private var sessionNotifiedWillDismiss = false
  private var sessionNotifiedDidDismiss = false
  private var pendingDismissReason: FKActionSheetDismissReason?

  var resolvedPanelHeight: CGFloat {
    lastResolvedPanelHeight
  }

  /// Whether this sheet is currently on screen.
  public var isPresented: Bool {
    presentingViewController != nil
  }

  var actionSheetPresentationController: FKActionSheetUIKitPresentationController? {
    presentationController as? FKActionSheetUIKitPresentationController
  }

  /// Creates an action sheet. Throws when `configuration` is invalid.
  public init(configuration: FKActionSheetConfiguration) throws {
    try FKActionSheetValidator.validate(configuration)
    let resolved = configuration.applyingSelectionState()
    self.configuration = resolved
    transitioningDelegateBox = FKActionSheetTransitioningDelegate(
      presentationConfiguration: resolved.presentation
    )
    super.init(nibName: nil, bundle: nil)

    if resolved.presentation.usesCustomModalPresentation {
      transitioningDelegateBox.attach(to: self)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UIViewController

  public override func loadView() {
    view = UIView()
    view.backgroundColor = .clear
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.accessibilityViewIsModal = true

    outsideTapRecognizer.cancelsTouchesInView = false
    outsideTapRecognizer.delegate = self
    view.addGestureRecognizer(outsideTapRecognizer)

    panelView.translatesAutoresizingMaskIntoConstraints = false
    panelView.clipsToBounds = true
    actionSheetView.delegate = self
    actionSheetView.translatesAutoresizingMaskIntoConstraints = false

    panelView.addSubview(actionSheetView)
    view.addSubview(panelView)

    panelHeightConstraint = panelView.heightAnchor.constraint(equalToConstant: 120)
    panelHeightConstraint?.isActive = true

    NSLayoutConstraint.activate([
      actionSheetView.topAnchor.constraint(equalTo: panelView.topAnchor),
      actionSheetView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
      actionSheetView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
      actionSheetView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),
    ])

    syncOutsideTapRecognizer()
    applyPanelChrome()
    _ = applyConfiguration(configuration, updateKind: .full)
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    session?.notifyWillPresent()
    updatePanelLayout(force: true)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    session?.notifyDidPresent()
    attemptScrollToSelectionOnPresent(animated: false)
  }

  public override func viewWillDisappear(_ animated: Bool) {
    if !sessionNotifiedWillDismiss {
      let reason = session?.captureDismissReason(default: .programmatic) ?? .programmatic
      session?.notifyWillDismiss(reason: reason)
      sessionNotifiedWillDismiss = true
    }
    super.viewWillDisappear(animated)
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if presentingViewController == nil, !sessionNotifiedDidDismiss {
      session?.notifyDidDismiss(reason: session?.lastCapturedReason ?? .programmatic)
      sessionNotifiedDidDismiss = true
    }
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = effectiveLayoutWidth()
    guard width > 0 else { return }
    if installedPanelLayout == nil {
      installPanelLayoutIfNeeded()
    } else {
      updatePanelWidthConstraint()
    }
    let widthChanged = abs(width - lastLayoutWidth) > 0.5
    let safeBottom = tableBottomContentInset()
    let safeBottomChanged = abs(safeBottom - lastTableSafeBottom) > 0.5
    guard widthChanged || safeBottomChanged else { return }
    lastLayoutWidth = width
    updatePanelLayout(force: safeBottomChanged && !widthChanged)
    applyPanelChrome()
  }

  public override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updatePanelLayout(force: true)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      actionSheetView.apply(configuration: configuration)
    }
    updatePanelLayout(force: true)
    applyPanelChrome()
  }

  // MARK: - Configuration

  /// Validates configuration without creating an instance.
  public static func validate(_ configuration: FKActionSheetConfiguration) throws {
    try FKActionSheetValidator.validate(configuration)
  }

  /// Replaces visible actions and header, then refreshes layout.
  ///
  /// - Returns: `false` when `configuration` fails validation (debug builds also emit `assertionFailure`).
  @discardableResult
  public func reload(configuration: FKActionSheetConfiguration) -> Bool {
    applyConfiguration(configuration.applyingSelectionState(), updateKind: .full)
  }

  /// Updates a single action in place when the identifier matches.
  ///
  /// - Returns: `false` when the resulting configuration fails validation.
  @discardableResult
  public func updateAction(_ action: FKActionSheetAction) -> Bool {
    applyConfiguration(configuration.replacingAction(action), updateKind: .singleAction(action))
  }

  /// Dismisses the sheet when visible.
  public func dismiss(
    reason: FKActionSheetDismissReason = .programmatic,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    stageDismissReason(reason)
    super.dismiss(animated: animated, completion: completion)
  }

  @discardableResult
  func applyConfiguration(
    _ configuration: FKActionSheetConfiguration,
    updateKind: ConfigurationUpdateKind
  ) -> Bool {
    do {
      try FKActionSheetValidator.validate(configuration)
    } catch {
      assertionFailure("FKActionSheet received invalid configuration: \(error)")
      return false
    }

    let wasLoading = self.configuration.isLoadingContentActive
    self.configuration = configuration
    session?.updateConfiguration(configuration)
    transitioningDelegateBox.updatePresentationConfiguration(configuration.presentation)

    switch updateKind {
    case .full:
      hasScrolledToSelectionOnPresent = false
      syncOutsideTapRecognizer()
      installPanelLayoutIfNeeded()
      lastLayoutWidth = 0
      lastResolvedPanelHeight = 0
      lastScrollEnabled = nil
      lastTableSafeBottom = -1
      panelView.backgroundColor = configuration.appearance.backgroundColor
      if configuration.presentation.style == .popover {
        view.backgroundColor = configuration.appearance.backgroundColor
      } else {
        view.backgroundColor = .clear
      }
      actionSheetView.apply(configuration: configuration)
      applyPanelChrome()
      updatePanelLayout(force: true, attemptSelectionScroll: true)
      if wasLoading, !configuration.isLoadingContentActive {
        announceActionContentAfterLoading()
      }
    case .selectionOnly:
      actionSheetView.syncSelectionConfiguration(configuration)
    case .singleAction(let action):
      actionSheetView.apply(configuration: configuration)
      actionSheetView.refreshAction(action)
      updatePanelLayout(force: false)
    }

    return true
  }

  func focusAccessibility() {
    let target = actionSheetView.accessibilityElementToFocus() ?? view
    UIAccessibility.post(notification: .screenChanged, argument: target)
  }

  /// Moves VoiceOver focus to action rows after a loading presentation ends.
  private func announceActionContentAfterLoading() {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isPresented, !self.configuration.isLoadingContentActive else { return }
      self.view.layoutIfNeeded()
      self.focusAccessibility()
    }
  }

  /// Scrolls a scrollable list to the restored selection once per configuration apply / present cycle.
  func attemptScrollToSelectionOnPresent(animated: Bool) {
    guard !hasScrolledToSelectionOnPresent else { return }
    guard configuration.selection.scrollsToSelectionOnPresent,
          configuration.selection.isSelectionActive,
          lastScrollEnabled == true
    else { return }

    let scroll = { [weak self] in
      guard let self, !self.hasScrolledToSelectionOnPresent else { return }
      if self.actionSheetView.scrollToRevealSelection(animated: animated) {
        self.hasScrolledToSelectionOnPresent = true
      }
    }

    // Defer once so panel height and table content size match the presented layout.
    if actionSheetView.isReadyForSelectionScroll {
      scroll()
    } else {
      DispatchQueue.main.async(execute: scroll)
    }
  }

  func dismissForBackdropTap() {
    guard configuration.presentation.allowsTapOutsideDismiss,
          configuration.presentation.usesCustomModalPresentation
    else { return }
    dismiss(reason: .tapOutside, animated: true)
  }

  func prepareForPresentationAnimation() {
    guard configuration.presentation.usesCustomModalPresentation else { return }
    view.layoutIfNeeded()
    setPresentationProgress(0, animated: false)
  }

  func setPresentationProgress(_ progress: CGFloat, animated: Bool) {
    presentationProgress = min(1, max(0, progress))
    let updates = {
      switch self.configuration.presentation.style {
      case .bottom:
        let offset = (1 - self.presentationProgress) * self.resolvedPanelHeight
        self.panelView.transform = CGAffineTransform(translationX: 0, y: offset)
        self.panelView.alpha = 1
      case .centered:
        let scale: CGFloat
        if self.centeredTransitionReveals {
          // Present: subtle zoom-down from 1.08 (matches FKSheetPresentationController `.center` / alertLikeCenter).
          scale = 1.08 - (0.08 * self.presentationProgress)
        } else {
          // Dismiss: fade out with slight shrink to 0.92.
          scale = 0.92 + (0.08 * self.presentationProgress)
        }
        self.panelView.transform = CGAffineTransform(scaleX: scale, y: scale)
        self.panelView.alpha = self.presentationProgress
      case .popover:
        self.panelView.transform = .identity
        self.panelView.alpha = self.presentationProgress
      }
    }
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: updates)
    } else {
      updates()
    }
  }

  func stageDismissReason(_ reason: FKActionSheetDismissReason) {
    pendingDismissReason = reason
  }

  func peekPendingDismissReason() -> FKActionSheetDismissReason? {
    pendingDismissReason
  }

  func consumePendingDismissReason(default reason: FKActionSheetDismissReason) -> FKActionSheetDismissReason {
    defer { pendingDismissReason = nil }
    return pendingDismissReason ?? reason
  }

  @objc
  private func handleOutsideTap(_ recognizer: UITapGestureRecognizer) {
    dismissForBackdropTap()
  }

  func syncOutsideTapRecognizer() {
    let isEnabled = configuration.presentation.allowsTapOutsideDismiss
      && configuration.presentation.usesCustomModalPresentation
    outsideTapRecognizer.isEnabled = isEnabled
  }
}

extension FKActionSheet: FKActionSheetViewDelegate {
  func actionSheetView(
    _ view: FKActionSheetView,
    didSelect action: FKActionSheetAction,
    sectionID: UUID?,
    isCancelGroup: Bool
  ) {
    onActionSelected?(action, sectionID, isCancelGroup)
  }

  func actionSheetView(
    _ view: FKActionSheetView,
    didToggle action: FKActionSheetAction,
    isOn: Bool
  ) {
    onToggleValueChanged?(action, isOn)
  }
}

extension FKActionSheet: UIGestureRecognizerDelegate {
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer === outsideTapRecognizer else { return true }
    let location = touch.location(in: view)
    let panelLocation = view.convert(location, to: panelView)
    return !panelView.point(inside: panelLocation, with: nil)
  }
}
