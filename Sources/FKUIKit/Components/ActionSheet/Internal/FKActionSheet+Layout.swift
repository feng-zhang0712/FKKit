import UIKit

extension FKActionSheet {
  enum InstalledPanelLayout: Equatable {
    case bottom
    case centered
    case popover
  }

  func installPanelLayoutIfNeeded() {
    let target = installedPanelLayout(for: configuration.presentation.style)
    guard target != installedPanelLayout else {
      updatePanelWidthConstraint()
      return
    }

    NSLayoutConstraint.deactivate(installedLayoutConstraints)
    installedLayoutConstraints.removeAll()
    panelWidthConstraint = nil
    panelCenterYConstraint = nil

    installedPanelLayout = target

    switch target {
    case .bottom:
      installBottomPanelLayout()
    case .centered:
      installCenteredPanelLayout()
    case .popover:
      installPopoverPanelLayout()
    }

    NSLayoutConstraint.activate(installedLayoutConstraints)
    updatePanelWidthConstraint()
    view.setNeedsLayout()
  }

  func contentLayoutWidth(for viewWidth: CGFloat) -> CGFloat {
    let presentation = configuration.presentation
    switch presentation.style {
    case .popover:
      let minimum = presentation.popoverMinimumWidth
      return viewWidth > 0 ? max(minimum, viewWidth) : minimum
    case .bottom, .centered:
      let inset = presentation.horizontalInset * 2
      let available = max(0, viewWidth - inset)
      return min(available, presentation.maxPanelWidth)
    }
  }

  /// Keeps the panel width in sync once the presented view has a non-zero width.
  func updatePanelWidthConstraint() {
    guard let panelWidthConstraint else { return }
    switch configuration.presentation.style {
    case .bottom, .centered:
      let width = contentLayoutWidth(for: effectiveLayoutWidth())
      guard width > 0, abs(panelWidthConstraint.constant - width) > 0.5 else { return }
      panelWidthConstraint.constant = width
    case .popover:
      break
    }
  }

  func effectiveLayoutWidth() -> CGFloat {
    if view.bounds.width > 0 {
      return view.bounds.width
    }
    if let containerWidth = view.superview?.bounds.width, containerWidth > 0 {
      return containerWidth
    }
    return view.window?.bounds.width ?? UIScreen.main.bounds.width
  }

  private func installedPanelLayout(for style: FKActionSheetPresentationStyle) -> InstalledPanelLayout {
    switch style {
    case .bottom:
      return .bottom
    case .centered:
      return .centered
    case .popover:
      return .popover
    }
  }

  private func installBottomPanelLayout() {
    guard let panelHeightConstraint else { return }
    panelHeightConstraint.isActive = true

    let width = panelView.widthAnchor.constraint(equalToConstant: contentLayoutWidth(for: effectiveLayoutWidth()))
    panelWidthConstraint = width

    installedLayoutConstraints = [
      width,
      panelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      panelHeightConstraint,
    ]
  }

  private func installCenteredPanelLayout() {
    guard let panelHeightConstraint else { return }
    panelHeightConstraint.isActive = true

    let width = panelView.widthAnchor.constraint(equalToConstant: contentLayoutWidth(for: effectiveLayoutWidth()))
    panelWidthConstraint = width

    let centerY = panelView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    panelCenterYConstraint = centerY

    installedLayoutConstraints = [
      width,
      panelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      centerY,
      panelHeightConstraint,
    ]
  }

  private func installPopoverPanelLayout() {
    panelHeightConstraint?.isActive = false

    installedLayoutConstraints = [
      panelView.topAnchor.constraint(equalTo: view.topAnchor),
      panelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      panelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ]
  }

  // MARK: - Panel sizing

  private static let minimumPanelHeight: CGFloat = 44

  func applyPanelChrome() {
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

  func updatePanelLayout(force: Bool) {
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

  func tableBottomContentInset() -> CGFloat {
    switch configuration.presentation.style {
    case .bottom:
      break
    case .centered, .popover:
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

  func maximumSheetHeight() -> CGFloat {
    let screenHeight = view.window?.bounds.height ?? UIScreen.main.bounds.height
    let fractionCap = screenHeight * configuration.presentation.maximumFitContentHeightFraction
    if let maximumPanelHeight = configuration.presentation.maximumPanelHeight {
      return min(fractionCap, maximumPanelHeight)
    }
    return fractionCap
  }
}
