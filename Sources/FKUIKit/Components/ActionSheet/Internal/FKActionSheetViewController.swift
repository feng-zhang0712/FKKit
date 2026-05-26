import UIKit

/// Action sheet container presented as a modal ``UIViewController`` (bottom, centered, or popover).
@MainActor
final class FKActionSheetViewController: UIViewController {
  var onActionSelected: ((FKActionSheetAction, UUID?, Bool) -> Void)?
  var onToggleValueChanged: ((FKActionSheetAction, Bool) -> Void)?
  var onPanelLayoutChange: (() -> Void)?

  let panelView = UIView()
  private(set) var presentationConfiguration: FKActionSheetPresentationConfiguration

  weak var session: FKActionSheetSession?

  private let actionSheetView = FKActionSheetView()
  private let transitioningDelegateBox: FKActionSheetTransitioningDelegate
  private lazy var outsideTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
  var configuration = FKActionSheetConfiguration()

  var panelHeightConstraint: NSLayoutConstraint?
  var panelWidthConstraint: NSLayoutConstraint?
  var panelCenterYConstraint: NSLayoutConstraint?
  var installedPanelLayout: InstalledPanelLayout?
  var installedLayoutConstraints: [NSLayoutConstraint] = []

  private var lastResolvedPanelHeight: CGFloat = 0
  private var lastLayoutWidth: CGFloat = 0
  private var lastScrollEnabled: Bool?
  private var lastTableSafeBottom: CGFloat = -1
  private var isUpdatingPanelLayout = false
  private var presentationProgress: CGFloat = 1
  private var sessionNotifiedWillDismiss = false
  private var sessionNotifiedDidDismiss = false

  var resolvedPanelHeight: CGFloat {
    lastResolvedPanelHeight
  }

  var actionSheetPresentationController: FKActionSheetUIKitPresentationController? {
    presentationController as? FKActionSheetUIKitPresentationController
  }

  init(configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    presentationConfiguration = configuration.presentation
    transitioningDelegateBox = FKActionSheetTransitioningDelegate(
      presentationConfiguration: configuration.presentation
    )
    super.init(nibName: nil, bundle: nil)

    if configuration.presentation.usesCustomModalPresentation {
      transitioningDelegateBox.attach(to: self)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = UIView()
    view.backgroundColor = .clear
  }

  override func viewDidLoad() {
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
    guard configuration.presentation.allowsTapOutsideDismiss,
          configuration.presentation.usesCustomModalPresentation
    else { return }
    session?.handle.dismiss(reason: .tapOutside, animated: true)
  }

  func prepareForPresentationAnimation() {
    guard presentationConfiguration.usesCustomModalPresentation else { return }
    view.layoutIfNeeded()
    setPresentationProgress(0, animated: false)
  }

  func setPresentationProgress(_ progress: CGFloat, animated: Bool) {
    presentationProgress = min(1, max(0, progress))
    let updates = {
      switch self.presentationConfiguration.style {
      case .bottom:
        let offset = (1 - self.presentationProgress) * self.resolvedPanelHeight
        self.panelView.transform = CGAffineTransform(translationX: 0, y: offset)
        self.panelView.alpha = 1
      case .centered:
        let scale = 0.9 + (0.1 * self.presentationProgress)
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

  func dismissSheet(
    animated: Bool,
    completion: (() -> Void)? = nil
  ) {
    dismiss(animated: animated, completion: completion)
  }

  @objc
  private func handleOutsideTap(_ recognizer: UITapGestureRecognizer) {
    dismissForBackdropTap()
  }

  private static let minimumPanelHeight: CGFloat = 44

  private func syncOutsideTapRecognizer() {
    let isEnabled = configuration.presentation.allowsTapOutsideDismiss
      && configuration.presentation.usesCustomModalPresentation
    outsideTapRecognizer.isEnabled = isEnabled
  }

  private func applyPanelChrome() {
    let radius = configuration.presentation.cornerRadius
    panelView.layer.cornerRadius = radius
    switch configuration.presentation.style {
    case .bottom:
      panelView.layer.maskedCorners = radius > 0
        ? [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        : []
    case .centered, .popover:
      panelView.layer.maskedCorners = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    }

    let roundedCorners: UIRectCorner = configuration.presentation.style == .bottom
      ? [.topLeft, .topRight]
      : .allCorners
    let shadowPath = UIBezierPath(
      roundedRect: panelView.bounds,
      byRoundingCorners: roundedCorners,
      cornerRadii: CGSize(width: radius, height: radius)
    ).cgPath
    panelView.layer.fk_applyShadow(configuration.presentation.containerShadow, path: shadowPath)
  }

  private func updatePanelLayout(force: Bool) {
    guard !isUpdatingPanelLayout else { return }
    isUpdatingPanelLayout = true
    defer { isUpdatingPanelLayout = false }

    let layoutWidth = contentLayoutWidth(for: effectiveLayoutWidth())
    updatePanelWidthConstraint()
    let tableSafeBottom = tableBottomContentInset()
    if force || abs(tableSafeBottom - lastTableSafeBottom) > 0.5 {
      lastTableSafeBottom = tableSafeBottom
      actionSheetView.updateBottomSafeAreaInset(tableSafeBottom)
    }

    let contentHeight = actionSheetView.measuredContentHeight(for: layoutWidth)
    let maximumContentHeight = maximumSheetHeight()
    let cappedContentHeight = min(contentHeight, maximumContentHeight)
    let shouldScroll = contentHeight > cappedContentHeight + 0.5

    if force || shouldScroll != lastScrollEnabled {
      lastScrollEnabled = shouldScroll
      actionSheetView.setScrollEnabled(shouldScroll)
    }

    let hostedHeight = max(cappedContentHeight, Self.minimumPanelHeight)
    guard hostedHeight >= Self.minimumPanelHeight else { return }

    let panelHeight: CGFloat
    switch configuration.presentation.style {
    case .popover:
      panelHeight = hostedHeight
    case .bottom, .centered:
      panelHeight = hostedHeight + tableSafeBottom
    }
    guard force || abs(panelHeight - lastResolvedPanelHeight) > 0.5 else { return }

    lastResolvedPanelHeight = panelHeight
    if configuration.presentation.style != .popover {
      panelHeightConstraint?.isActive = true
      panelHeightConstraint?.constant = panelHeight
    }
    preferredContentSize = CGSize(width: layoutWidth, height: panelHeight)

    if presentationProgress < 1 {
      setPresentationProgress(presentationProgress, animated: false)
    }

    onPanelLayoutChange?()
    view.setNeedsLayout()
  }

  private func tableBottomContentInset() -> CGFloat {
    switch configuration.presentation.style {
    case .bottom:
      break
    case .centered:
      return 0
    case .popover:
      return 0
    }

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
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer === outsideTapRecognizer else { return true }
    let location = touch.location(in: view)
    let panelLocation = view.convert(location, to: panelView)
    return !panelView.point(inside: panelLocation, with: nil)
  }
}
