import UIKit

extension FKActionSheetViewController {
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
}
