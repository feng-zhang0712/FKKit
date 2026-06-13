import UIKit

extension FKChipGroup {
  // MARK: - Flow layout

  @discardableResult
  func ensureFlowContainer() -> FKFlowLayoutView {
    if let flowContainer { return flowContainer }

    let container = FKFlowLayoutView()
    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(container)
    flowContainer = container
    setNeedsLayout()
    return container
  }

  func releaseFlowContainer() {
    flowContainer?.removeFromSuperview()
    flowContainer = nil
  }

  // MARK: - Horizontal scroll layout

  @discardableResult
  func ensureScrollLayout() -> (scrollView: UIScrollView, contentView: FKFlowLayoutView) {
    if let scrollView, let scrollContentView {
      return (scrollView, scrollContentView)
    }

    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false

    let contentView = FKFlowLayoutView()
    contentView.allowsWrap = false
    scrollView.addSubview(contentView)
    addSubview(scrollView)

    self.scrollView = scrollView
    scrollContentView = contentView
    setNeedsLayout()
    return (scrollView, contentView)
  }

  func releaseScrollLayout() {
    scrollContentView?.removeFromSuperview()
    scrollView?.removeFromSuperview()
    scrollContentView = nil
    scrollView = nil
  }

  /// Attaches only the layout container required by ``FKChipGroupConfiguration/layoutMode``.
  func syncLayoutContainers() {
    switch configuration.layoutMode {
    case .flow:
      releaseScrollLayout()
      _ = ensureFlowContainer()
    case .horizontalScroll:
      releaseFlowContainer()
      _ = ensureScrollLayout()
    }
  }

  func activeChipContainer() -> UIView {
    switch configuration.layoutMode {
    case .flow:
      return ensureFlowContainer()
    case .horizontalScroll:
      return ensureScrollLayout().contentView
    }
  }

  func applyLayoutContainerConfiguration() {
    switch configuration.layoutMode {
    case .flow(let wrap):
      let container = ensureFlowContainer()
      container.itemSpacing = configuration.itemSpacing
      container.lineSpacing = configuration.lineSpacing
      container.contentInsets = configuration.contentInsets
      container.allowsWrap = wrap
    case .horizontalScroll:
      let contentView = ensureScrollLayout().contentView
      contentView.itemSpacing = configuration.itemSpacing
      contentView.lineSpacing = configuration.lineSpacing
      contentView.contentInsets = configuration.contentInsets
      contentView.allowsWrap = false
    }
  }
}
