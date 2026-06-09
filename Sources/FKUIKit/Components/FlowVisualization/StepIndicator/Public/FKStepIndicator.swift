import UIKit

/// Horizontal linear step progress for checkout flows, onboarding headers, and wizard navigation.
///
/// Assign ``configuration`` for layout and appearance. Set ``items`` explicitly or drive states with
/// ``currentStepIndex``. Global defaults: ``FKStepIndicator/defaultConfiguration`` or ``FKStepIndicatorDefaults/configuration``.
@MainActor
public final class FKStepIndicator: UIControl {
  /// Baseline copied by `init(frame:)` until you replace ``configuration``.
  public static var defaultConfiguration: FKStepIndicatorConfiguration {
    get { FKStepIndicatorDefaults.configuration }
    set { FKStepIndicatorDefaults.configuration = newValue }
  }

  /// Style and behavior; assigning triggers layout and appearance refresh.
  public var configuration: FKStepIndicatorConfiguration = FKStepIndicator.defaultConfiguration {
    didSet { applyConfigurationChange() }
  }

  /// Steps displayed left-to-right (mirrored in RTL).
  public var items: [FKFlowStepItem] = [] {
    didSet {
      guard !isSyncingContent else { return }
      applyItemsChange()
    }
  }

  /// When set, derives completed/upcoming states by index; explicit state at this index wins.
  public var currentStepIndex: Int? {
    didSet {
      guard !isSyncingContent else { return }
      applyItemsChange()
    }
  }

  /// Optional delegate for selection policy.
  public weak var delegate: FKStepIndicatorDelegate?

  /// Closure alternative to ``FKStepIndicatorDelegate``.
  public var onStepSelected: ((Int, FKFlowStepItem) -> Void)?

  /// Shows an indeterminate indicator on the current step and disables selection.
  public var isLoading = false {
    didSet {
      applyInteractionMode()
      refreshPresentation()
    }
  }

  /// Partial fill (`0…1`) on the connector after the current step when ``FKStepIndicatorLayoutConfiguration/showsPartialConnectorFill`` is enabled.
  public var currentStepProgress: CGFloat = 0 {
    didSet {
      let clamped = min(max(0, currentStepProgress), 1)
      if clamped != currentStepProgress {
        currentStepProgress = clamped
        return
      }
      guard configuration.layout.showsPartialConnectorFill else { return }
      setNeedsLayout()
      layoutIfNeeded()
    }
  }

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private var edgeFadeView: FKFlowScrollEdgeFadeView?
  private var stepViews: [FKStepIndicatorStepView] = []
  private var connectorLayers: [FKFlowConnectorLayer] = []
  private var resolvedItems: [FKFlowStepItem] = []
  private var latestMetrics = FKStepIndicatorLayoutEngine.Metrics(stepMetrics: [], contentSize: .zero, needsHorizontalScroll: false)
  private var isSyncingContent = false

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKStepIndicatorConfiguration = FKStepIndicator.defaultConfiguration,
    items: [FKFlowStepItem] = [],
    currentStepIndex: Int? = nil
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    isSyncingContent = true
    self.items = items
    self.currentStepIndex = currentStepIndex
    isSyncingContent = false
    applyItemsChange()
  }

  // MARK: - Public API

  /// Updates the active step index with optional animation.
  public func setCurrentStep(_ index: Int, animated: Bool) {
    isSyncingContent = true
    currentStepIndex = index
    isSyncingContent = false
    applyItemsChange()
    scrollToStep(index, animated: animated)
  }

  /// Replaces all steps with optional animation.
  public func setItems(_ items: [FKFlowStepItem], animated: Bool) {
    isSyncingContent = true
    self.items = items
    isSyncingContent = false
    applyItemsChange()
  }

  /// Scrolls the horizontal content so the step at `index` is visible.
  public func scrollToStep(_ index: Int, animated: Bool) {
    setNeedsLayout()
    layoutIfNeeded()
    guard index >= 0, index < latestMetrics.stepMetrics.count else { return }
    let metric = latestMetrics.stepMetrics[index]
    var frame = metric.nodeFrame
    if let titleFrame = metric.titleFrame { frame = frame.union(titleFrame) }
    if let subtitleFrame = metric.subtitleFrame { frame = frame.union(subtitleFrame) }
    frame = frame.insetBy(dx: -24, dy: -8)
    if canScrollHorizontally {
      scrollHorizontallyToCenter(frame, animated: animated)
    } else {
      scrollAncestorToReveal(frame, animated: animated)
    }
  }

  private var canScrollHorizontally: Bool {
    latestMetrics.needsHorizontalScroll
      || scrollView.contentSize.width > scrollView.bounds.width + 1
  }

  public override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    return FKStepIndicatorLayoutEngine.intrinsicContentSize(
      items: resolvedItems,
      configuration: configuration,
      width: width,
      traitCollection: traitCollection
    )
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    FKStepIndicatorLayoutEngine.intrinsicContentSize(
      items: resolvedItems,
      configuration: configuration,
      width: size.width > 0 ? size.width : UIScreen.main.bounds.width,
      traitCollection: traitCollection
    )
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds
    edgeFadeView?.frame = bounds

    let layoutDirection = effectiveUserInterfaceLayoutDirection
    latestMetrics = FKStepIndicatorLayoutEngine.metrics(
      items: resolvedItems,
      configuration: configuration,
      bounds: bounds,
      layoutDirection: layoutDirection,
      traitCollection: traitCollection
    )

    contentView.frame = CGRect(origin: .zero, size: latestMetrics.contentSize)
    scrollView.contentSize = latestMetrics.contentSize
    scrollView.isScrollEnabled = canScrollHorizontally

    for (index, stepMetric) in latestMetrics.stepMetrics.enumerated() {
      guard index < stepViews.count else { break }
      let stepView = stepViews[index]
      let stepBounds = stepContentBounds(for: stepMetric)
      stepView.frame = stepBounds
      let offset = stepBounds.origin
      stepView.nodeView.frame = stepMetric.nodeFrame.offsetBy(dx: -offset.x, dy: -offset.y)
      stepView.titleLabel.frame = (stepMetric.titleFrame ?? .zero).offsetBy(dx: -offset.x, dy: -offset.y)
      if let subtitleLabel = stepView.subtitleLabel, let subtitleFrame = stepMetric.subtitleFrame {
        subtitleLabel.frame = subtitleFrame.offsetBy(dx: -offset.x, dy: -offset.y)
      }

      if index < connectorLayers.count, let start = stepMetric.connectorStart, let end = stepMetric.connectorEnd {
        let layer = connectorLayers[index]
        layer.isHidden = false
        let item = resolvedItems[index]
        let completed = connectorIsCompleted(from: item, configuration: configuration)
        let partialProgress = partialConnectorProgress(afterStepAt: index)
        layer.apply(
          style: configuration.appearance.connector,
          completed: completed,
          partialProgress: partialProgress
        )
        let layerFrame = CGRect(
          x: start.x,
          y: start.y - configuration.appearance.connector.thickness * 0.5,
          width: end.x - start.x,
          height: configuration.appearance.connector.thickness
        )
        layer.frame = layerFrame
        layer.updatePath(
          from: CGPoint(x: 0, y: layer.bounds.midY),
          to: CGPoint(x: layer.bounds.width, y: layer.bounds.midY),
          partialProgress: partialProgress,
          animated: false,
          duration: 0
        )
        layer.setHiddenFromAccessibility(configuration.accessibility.hidesConnectorsFromAccessibility)
      }
    }

    let activeConnectorCount = max(0, latestMetrics.stepMetrics.count - 1)
    for index in activeConnectorCount ..< connectorLayers.count {
      connectorLayers[index].isHidden = true
    }

    updateEdgeFadeIfNeeded()
    applyInteractionMode()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      invalidateIntrinsicContentSize()
      setNeedsLayout()
    }
  }

  // MARK: - Private

  private func commonInit() {
    backgroundColor = .clear
    isAccessibilityElement = false
    accessibilityElements = []

    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.alwaysBounceHorizontal = false
    scrollView.delegate = self
    addSubview(scrollView)
    scrollView.addSubview(contentView)

    applyInteractionMode()
  }

  private func applyConfigurationChange() {
    reconcileSubviews()
    applyInteractionMode()
    applyItemsChange()
  }

  private func applyItemsChange() {
    resolvedItems = FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: currentStepIndex)
    reconcileSubviews()
    refreshPresentation()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateContainerAccessibility()
  }

  private func reconcileSubviews() {
    while stepViews.count < resolvedItems.count {
      let view = FKStepIndicatorStepView()
      view.onTap = { [weak self] index in
        self?.handleStepTap(at: index)
      }
      stepViews.append(view)
      contentView.addSubview(view)
    }
    while stepViews.count > resolvedItems.count {
      stepViews.removeLast().removeFromSuperview()
    }

    let connectorCount = max(0, resolvedItems.count - 1)
    while connectorLayers.count < connectorCount {
      let layer = FKFlowConnectorLayer()
      contentView.layer.insertSublayer(layer, at: 0)
      connectorLayers.append(layer)
    }
    while connectorLayers.count > connectorCount {
      connectorLayers.removeLast().removeFromSuperlayer()
    }
  }

  private func refreshPresentation() {
    for (index, item) in resolvedItems.enumerated() where index < stepViews.count {
      let stepIsLoading = isLoading && item.state == .current
      let isSelectable = configuration.interaction.allowsSelection
        && !isLoading
        && (item.isInteractive ?? configuration.interaction.selectableStates.contains(item.state))
      stepViews[index].apply(
        item: item,
        stepIndex: index,
        totalCount: resolvedItems.count,
        configuration: configuration,
        isLoading: stepIsLoading,
        isSelectable: isSelectable
      )
    }
    setNeedsLayout()
  }

  private func applyInteractionMode() {
    let interactive = configuration.interaction.allowsSelection && !isLoading
    isUserInteractionEnabled = interactive || canScrollHorizontally
    scrollView.isUserInteractionEnabled = true
    for stepView in stepViews {
      stepView.isUserInteractionEnabled = interactive
      stepView.gestureRecognizers?.forEach { $0.isEnabled = interactive }
    }
  }

  private func updateEdgeFadeIfNeeded() {
    let shouldShow = configuration.appearance.showsScrollEdgeFade && canScrollHorizontally
    if shouldShow {
      let fadeView = edgeFadeView ?? {
        let view = FKFlowScrollEdgeFadeView()
        addSubview(view)
        edgeFadeView = view
        return view
      }()
      fadeView.frame = bounds
      fadeView.update(scrollView: scrollView, isEnabled: true)
    } else {
      edgeFadeView?.removeFromSuperview()
      edgeFadeView = nil
    }
  }

  private func handleStepTap(at index: Int) {
    guard configuration.interaction.allowsSelection, !isLoading else { return }
    guard index >= 0, index < resolvedItems.count else { return }
    let item = resolvedItems[index]
    let selectable = item.isInteractive ?? configuration.interaction.selectableStates.contains(item.state)
    guard selectable else { return }
    guard delegate?.stepIndicator(self, shouldSelectStepAt: index) ?? true else { return }

    if configuration.interaction.hapticOnSelect {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    delegate?.stepIndicator(self, didSelectStepAt: index)
    onStepSelected?(index, item)
  }

  private func connectorIsCompleted(from item: FKFlowStepItem, configuration: FKStepIndicatorConfiguration) -> Bool {
    if item.state == .completed { return true }
    if item.state == .skipped, configuration.appearance.treatsSkippedAsCompletedForConnectors { return true }
    return false
  }

  private func partialConnectorProgress(afterStepAt index: Int) -> CGFloat? {
    guard configuration.layout.showsPartialConnectorFill else { return nil }
    guard index >= 0, index < resolvedItems.count - 1 else { return nil }
    guard resolvedItems[index].state == .current else { return nil }
    guard resolvedItems[index + 1].state == .upcoming else { return nil }
    return currentStepProgress
  }

  private func updateContainerAccessibility() {
    accessibilityElements = stepViews
    if let custom = configuration.accessibility.customLabel {
      accessibilityLabel = custom
    }
  }

  private func stepContentBounds(for metric: FKStepIndicatorLayoutEngine.StepMetrics) -> CGRect {
    var bounds = metric.nodeFrame.union(metric.touchFrame)
    if let titleFrame = metric.titleFrame { bounds = bounds.union(titleFrame) }
    if let subtitleFrame = metric.subtitleFrame { bounds = bounds.union(subtitleFrame) }
    return bounds
  }

  private func scrollHorizontallyToCenter(_ frameInContentView: CGRect, animated: Bool) {
    let targetRect = contentView.convert(frameInContentView, to: scrollView)
    let centeredOffsetX = targetRect.midX - scrollView.bounds.width * 0.5
    let maxOffsetX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
    let clampedOffsetX = min(max(0, centeredOffsetX), maxOffsetX)
    scrollView.setContentOffset(CGPoint(x: clampedOffsetX, y: 0), animated: animated)
  }

  private func scrollAncestorToReveal(_ frameInContentView: CGRect, animated: Bool) {
    var view: UIView? = superview
    while let ancestor = view {
      if let scrollView = ancestor as? UIScrollView, scrollView !== self.scrollView {
        let targetRect = contentView.convert(frameInContentView, to: scrollView).insetBy(dx: -24, dy: -24)
        let centeredOffsetY = targetRect.midY - scrollView.bounds.height * 0.5
        let maxOffsetY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedOffsetY = min(max(0, centeredOffsetY), maxOffsetY)
        scrollView.setContentOffset(
          CGPoint(x: scrollView.contentOffset.x, y: clampedOffsetY),
          animated: animated
        )
        return
      }
      view = ancestor.superview
    }
  }
}

extension FKStepIndicator: UIScrollViewDelegate {
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    edgeFadeView?.update(scrollView: scrollView, isEnabled: true)
  }
}
