import UIKit

/// Root view that forwards hits outside the sheet panel to the dimmed backdrop.
@MainActor
private final class FKActionSheetRootView: UIView {
  weak var panelView: UIView?
  var allowsBackdropTapDismiss = true

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard allowsBackdropTapDismiss, let panelView else {
      return super.hitTest(point, with: event)
    }
    if panelView.frame.contains(point) {
      return super.hitTest(point, with: event)
    }
    return nil
  }
}

/// Bottom action sheet container presented as a custom modal ``UIViewController``.
@MainActor
final class FKActionSheetViewController: UIViewController {
  var onActionSelected: ((FKActionSheetAction, UUID?, Bool) -> Void)?
  var onToggleValueChanged: ((FKActionSheetAction, Bool) -> Void)?
  var onPanelLayoutChange: (() -> Void)?

  let panelView = UIView()
  private(set) var presentationConfiguration: FKActionSheetPresentationConfiguration
  private(set) var interactiveDismissal: FKActionSheetInteractiveDismissal?

  weak var session: FKActionSheetSession?

  private let actionSheetView = FKActionSheetView()
  private let transitioningDelegateBox: FKActionSheetTransitioningDelegate
  private var configuration = FKActionSheetConfiguration()
  private var panelHeightConstraint: NSLayoutConstraint?
  private var lastResolvedPanelHeight: CGFloat = 0
  private var lastLayoutWidth: CGFloat = 0
  private var lastScrollEnabled: Bool?
  private var lastTableSafeBottom: CGFloat = -1
  private var isUpdatingPanelLayout = false
  private var presentationProgress: CGFloat = 1
  private var sessionNotifiedWillDismiss = false
  private var sessionNotifiedDidDismiss = false
  private(set) var isInteractiveDismissalActive = false

  var resolvedPanelHeight: CGFloat {
    lastResolvedPanelHeight
  }

  var actionSheetPresentationController: FKActionSheetUIKitPresentationController? {
    presentationController as? FKActionSheetUIKitPresentationController
  }

  init(configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    presentationConfiguration = configuration.presentation
    transitioningDelegateBox = FKActionSheetTransitioningDelegate(presentationConfiguration: configuration.presentation)
    super.init(nibName: nil, bundle: nil)
    transitioningDelegateBox.attach(to: self)
    if configuration.presentation.allowsSwipeDismiss {
      let dismissal = FKActionSheetInteractiveDismissal()
      dismissal.attach(to: self)
      interactiveDismissal = dismissal
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = FKActionSheetRootView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.accessibilityViewIsModal = true

    panelView.translatesAutoresizingMaskIntoConstraints = false
    panelView.clipsToBounds = true
    actionSheetView.delegate = self
    actionSheetView.translatesAutoresizingMaskIntoConstraints = false

    panelView.addSubview(actionSheetView)
    view.addSubview(panelView)

    let height = panelView.heightAnchor.constraint(equalToConstant: 120)
    panelHeightConstraint = height

    NSLayoutConstraint.activate([
      panelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      panelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      height,

      actionSheetView.topAnchor.constraint(equalTo: panelView.topAnchor),
      actionSheetView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
      actionSheetView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
      actionSheetView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor),
    ])

    if let rootView = view as? FKActionSheetRootView {
      rootView.panelView = panelView
      rootView.allowsBackdropTapDismiss = configuration.presentation.allowsTapOutsideDismiss
    }

    applyPanelChrome()
    apply(configuration: configuration)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    session?.notifyWillPresent()
    updatePanelLayout(force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    session?.notifyDidPresent()
    updatePanelLayout(force: true)
  }

  override func viewWillDisappear(_ animated: Bool) {
    if !sessionNotifiedWillDismiss {
      let reason = session?.captureDismissReason(default: .programmatic) ?? .programmatic
      session?.notifyWillDismiss(reason: reason)
      sessionNotifiedWillDismiss = true
    }
    super.viewWillDisappear(animated)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if presentingViewController == nil, !sessionNotifiedDidDismiss {
      session?.notifyDidDismiss(reason: session?.lastCapturedReason ?? .programmatic)
      sessionNotifiedDidDismiss = true
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = view.bounds.width
    guard width > 0 else { return }
    let widthChanged = abs(width - lastLayoutWidth) > 0.5
    let safeBottom = tableBottomContentInset()
    let safeBottomChanged = abs(safeBottom - lastTableSafeBottom) > 0.5
    guard widthChanged || safeBottomChanged else { return }
    lastLayoutWidth = width
    updatePanelLayout(force: safeBottomChanged && !widthChanged)
    applyPanelChrome()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updatePanelLayout(force: true)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      actionSheetView.apply(configuration: configuration)
    }
    updatePanelLayout(force: true)
    applyPanelChrome()
  }

  func apply(configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    presentationConfiguration = configuration.presentation
    if let rootView = view as? FKActionSheetRootView {
      rootView.allowsBackdropTapDismiss = configuration.presentation.allowsTapOutsideDismiss
    }
    lastLayoutWidth = 0
    lastResolvedPanelHeight = 0
    lastScrollEnabled = nil
    lastTableSafeBottom = -1
    panelView.backgroundColor = configuration.appearance.backgroundColor
    actionSheetView.apply(configuration: configuration)
    applyPanelChrome()
    updatePanelLayout(force: true)
  }

  func refreshAction(_ action: FKActionSheetAction) {
    configuration = configuration.replacingAction(action)
    actionSheetView.refreshAction(action)
    updatePanelLayout(force: true)
  }

  func focusAccessibility() {
    UIAccessibility.post(notification: .screenChanged, argument: view)
  }

  func dismissForBackdropTap() {
    guard configuration.presentation.allowsTapOutsideDismiss else { return }
    session?.handle.dismiss(reason: .tapOutside, animated: true)
  }

  func beginInteractiveDismissal(using interaction: FKActionSheetInteractiveDismissal) {
    isInteractiveDismissalActive = true
    session?.captureDismissReason(default: .swipe)
    session?.notifyWillDismiss(reason: .swipe)
    sessionNotifiedWillDismiss = true
    dismiss(animated: true)
  }

  func cancelInteractiveDismissal(using interaction: FKActionSheetInteractiveDismissal) {
    isInteractiveDismissalActive = false
    sessionNotifiedWillDismiss = false
    setPresentationProgress(1, animated: true)
    actionSheetPresentationController?.setBackdropAlpha(presentationConfiguration.backdropAlpha)
  }

  func prepareForPresentationAnimation() {
    view.layoutIfNeeded()
    setPresentationProgress(0, animated: false)
  }

  func setPresentationProgress(_ progress: CGFloat, animated: Bool) {
    presentationProgress = min(1, max(0, progress))
    let offset = (1 - presentationProgress) * resolvedPanelHeight
    let updates = {
      self.panelView.transform = CGAffineTransform(translationX: 0, y: offset)
    }
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: updates)
    } else {
      updates()
    }
  }

  func dismissSheet(
    animated: Bool,
    completion: (() -> Void)? = nil
  ) {
    dismiss(animated: animated, completion: completion)
  }

  var isBeingDismissedInteractively: Bool {
    isInteractiveDismissalActive
  }

  private static let minimumPanelHeight: CGFloat = 44

  private func applyPanelChrome() {
    let radius = configuration.presentation.cornerRadius
    panelView.layer.cornerRadius = radius
    if radius > 0 {
      panelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    let shadowPath = UIBezierPath(
      roundedRect: panelView.bounds,
      byRoundingCorners: [.topLeft, .topRight],
      cornerRadii: CGSize(width: radius, height: radius)
    ).cgPath
    panelView.layer.fk_applyShadow(configuration.presentation.containerShadow, path: shadowPath)
  }

  private func updatePanelLayout(force: Bool) {
    guard !isUpdatingPanelLayout else { return }
    isUpdatingPanelLayout = true
    defer { isUpdatingPanelLayout = false }

    let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
    let tableSafeBottom = tableBottomContentInset()
    if force || abs(tableSafeBottom - lastTableSafeBottom) > 0.5 {
      lastTableSafeBottom = tableSafeBottom
      actionSheetView.updateBottomSafeAreaInset(tableSafeBottom)
    }

    let contentHeight = actionSheetView.measuredContentHeight(for: width)
    let maximumContentHeight = maximumSheetHeight()
    let cappedContentHeight = min(contentHeight, maximumContentHeight)
    let shouldScroll = contentHeight > cappedContentHeight + 0.5

    if force || shouldScroll != lastScrollEnabled {
      lastScrollEnabled = shouldScroll
      actionSheetView.setScrollEnabled(shouldScroll)
    }

    let hostedHeight = max(cappedContentHeight, Self.minimumPanelHeight)
    guard hostedHeight >= Self.minimumPanelHeight else { return }

    let panelHeight = hostedHeight + tableSafeBottom
    guard force || abs(panelHeight - lastResolvedPanelHeight) > 0.5 else { return }

    lastResolvedPanelHeight = panelHeight
    panelHeightConstraint?.constant = panelHeight
    preferredContentSize = CGSize(width: width, height: panelHeight)

    if presentationProgress < 1 {
      setPresentationProgress(presentationProgress, animated: false)
    }

    onPanelLayoutChange?()
    view.setNeedsLayout()
  }

  private func tableBottomContentInset() -> CGFloat {
    if view.safeAreaInsets.bottom > 0 {
      return view.safeAreaInsets.bottom
    }
    if let windowBottom = view.window?.safeAreaInsets.bottom, windowBottom > 0 {
      return windowBottom
    }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = scenes
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
    return keyWindow?.safeAreaInsets.bottom ?? 0
  }

  private func maximumSheetHeight() -> CGFloat {
    let screenHeight = view.window?.bounds.height ?? UIScreen.main.bounds.height
    let fractionCap = screenHeight * configuration.presentation.maximumFitContentHeightFraction
    if let maximumPanelHeight = configuration.presentation.resolvedMaximumPanelHeight {
      return min(fractionCap, maximumPanelHeight)
    }
    return fractionCap
  }
}

extension FKActionSheetViewController: FKActionSheetViewDelegate {
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

extension FKActionSheetViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    false
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: view)
    return velocity.y > abs(velocity.x)
  }
}
