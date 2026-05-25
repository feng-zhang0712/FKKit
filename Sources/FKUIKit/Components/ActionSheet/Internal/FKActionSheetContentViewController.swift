import UIKit

/// Hosted content for ``FKPresentationController``; owns sizing and row interaction wiring.
@MainActor
final class FKActionSheetContentViewController: UIViewController {
  var onPreferredContentSizeChange: (() -> Void)?
  var onActionSelected: ((FKActionSheetAction, UUID?, Bool) -> Void)?

  private let actionSheetView = FKActionSheetView()
  private var configuration = FKActionSheetConfiguration()
  private var lastResolvedContentSize: CGSize = .zero
  private var lastLayoutWidth: CGFloat = 0
  private var lastScrollEnabled: Bool?
  private var lastTableSafeBottom: CGFloat = -1
  private var isUpdatingPreferredContentSize = false
  weak var session: FKActionSheetSession?
  var onToggleValueChanged: ((FKActionSheetAction, Bool) -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.accessibilityViewIsModal = true
    actionSheetView.delegate = self
    view.addSubview(actionSheetView)

    NSLayoutConstraint.activate([
      actionSheetView.topAnchor.constraint(equalTo: view.topAnchor),
      actionSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      actionSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      actionSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  func apply(configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    lastLayoutWidth = 0
    lastResolvedContentSize = .zero
    lastScrollEnabled = nil
    lastTableSafeBottom = -1
    view.backgroundColor = configuration.appearance.backgroundColor
    actionSheetView.apply(configuration: configuration)
    updatePreferredContentSize(force: true)
  }

  /// Updates one row without a full table reload when the row is already visible.
  func refreshAction(_ action: FKActionSheetAction) {
    configuration = configuration.replacingAction(action)
    actionSheetView.refreshAction(action)
    updatePreferredContentSize(force: true)
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
    updatePreferredContentSize(force: safeBottomChanged && !widthChanged)
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updatePreferredContentSize(force: true)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      actionSheetView.apply(configuration: configuration)
    }
    updatePreferredContentSize(force: true)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updatePreferredContentSize(force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updatePreferredContentSize(force: true)
  }

  func focusAccessibility() {
    UIAccessibility.post(notification: .screenChanged, argument: view)
  }

  private static let minimumReportedHeight: CGFloat = 44

  private func updatePreferredContentSize(force: Bool) {
    guard !isUpdatingPreferredContentSize else { return }
    isUpdatingPreferredContentSize = true
    defer { isUpdatingPreferredContentSize = false }

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

    // Hosted view height matches scrollable list area; presentation shell adds safe-bottom via policy.
    let hostedHeight = max(cappedContentHeight, Self.minimumReportedHeight)
    guard hostedHeight >= Self.minimumReportedHeight else { return }

    let panelHeight = hostedHeight + tableSafeBottom
    let resolved = CGSize(width: width, height: panelHeight)
    guard force
      || abs(resolved.width - lastResolvedContentSize.width) > 0.5
      || abs(resolved.height - lastResolvedContentSize.height) > 0.5
    else { return }

    lastResolvedContentSize = resolved
    guard preferredContentSize != resolved else { return }
    preferredContentSize = resolved
    onPreferredContentSizeChange?()
  }

  /// Bottom inset reserved below the last row (home indicator).
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

extension FKActionSheetContentViewController: FKActionSheetViewDelegate {
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
