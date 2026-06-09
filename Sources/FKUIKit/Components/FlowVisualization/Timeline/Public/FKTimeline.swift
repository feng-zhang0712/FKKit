import UIKit

/// Vertical event timeline for logistics, order history, audit trails, and activity feeds.
///
/// Assign ``configuration`` for layout and appearance. Provide flat ``items`` or grouped ``sections``.
/// Global defaults: ``FKTimeline/defaultConfiguration`` or ``FKTimelineDefaults/configuration``.
@MainActor
public final class FKTimeline: UIView {
  /// Baseline copied by `init(frame:)` until you replace ``configuration``.
  public static var defaultConfiguration: FKTimelineConfiguration {
    get { FKTimelineDefaults.configuration }
    set { FKTimelineDefaults.configuration = newValue }
  }

  /// Style and behavior; assigning triggers layout and appearance refresh.
  public var configuration: FKTimelineConfiguration = FKTimeline.defaultConfiguration {
    didSet { applyConfigurationChange() }
  }

  /// Flat timeline rows used when ``sections`` is empty.
  public var items: [FKFlowStepItem] = [] {
    didSet {
      guard !isSyncingContent else { return }
      applyItemsChange()
    }
  }

  /// Grouped rows; when non-empty, replaces flat ``items`` for display.
  public var sections: [FKTimelineSection] = [] {
    didSet {
      guard !isSyncingContent else { return }
      applyItemsChange()
    }
  }

  /// Optional delegate for selection policy.
  public weak var delegate: FKTimelineDelegate?

  /// Closure alternative to ``FKTimelineDelegate``.
  public var onItemSelected: ((Int, FKFlowStepItem) -> Void)?

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private var rowViews: [FKTimelineRowView] = []
  private var sectionLabels: [UILabel?] = []
  private var connectorLayers: [FKFlowConnectorLayer] = []
  private var displaySections: [FKTimelineSection] = []
  private var flatItems: [FKFlowStepItem] = []
  private var expandedItemIDs: Set<String> = []
  private var latestMetrics = FKTimelineLayoutEngine.Metrics(sections: [], contentSize: .zero)
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
    configuration: FKTimelineConfiguration = FKTimeline.defaultConfiguration,
    items: [FKFlowStepItem] = []
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    isSyncingContent = true
    self.items = items
    isSyncingContent = false
    applyItemsChange()
  }

  // MARK: - Public API

  /// Replaces timeline content with optional animation.
  public func setItems(_ items: [FKFlowStepItem], animated: Bool) {
    isSyncingContent = true
    self.items = items
    sections = []
    isSyncingContent = false
    applyItemsChange()
  }

  /// Scrolls to the row with the given identifier.
  public func scrollToStep(id: String, animated: Bool) {
    setNeedsLayout()
    layoutIfNeeded()
    for section in latestMetrics.sections {
      for row in section.rows where row.itemID == id {
        var frame = row.nodeFrame.union(row.contentFrame)
        frame = frame.insetBy(dx: 0, dy: -24)
        if configuration.layout.scrollable || scrollView.contentSize.height > scrollView.bounds.height + 1 {
          scrollVerticallyToCenter(frame, animated: animated)
        } else {
          scrollAncestorToReveal(frame, animated: animated)
        }
        return
      }
    }
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: latestMetrics.contentSize.height)
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let metrics = FKTimelineLayoutEngine.metrics(
      sections: displaySections,
      configuration: configuration,
      bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      traitCollection: traitCollection,
      expandedItemIDs: expandedItemIDs
    )
    return metrics.contentSize
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds
    scrollView.isScrollEnabled = configuration.layout.scrollable

    latestMetrics = FKTimelineLayoutEngine.metrics(
      sections: displaySections,
      configuration: configuration,
      bounds: bounds,
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      traitCollection: traitCollection,
      expandedItemIDs: expandedItemIDs
    )

    contentView.frame = CGRect(origin: .zero, size: latestMetrics.contentSize)
    scrollView.contentSize = latestMetrics.contentSize

    var rowIndex = 0
    var connectorIndex = 0
    for (sectionIndex, sectionMetric) in latestMetrics.sections.enumerated() {
      let sectionTitle = displaySections[sectionIndex].title
      if sectionTitle.isEmpty {
        removeSectionLabelIfNeeded(at: sectionIndex)
      } else if let titleFrame = sectionMetric.titleFrame {
        let label = ensureSectionLabel(at: sectionIndex)
        label.frame = titleFrame
        label.text = sectionTitle
      }

      for rowMetric in sectionMetric.rows {
        guard rowIndex < rowViews.count else { break }
        let rowView = rowViews[rowIndex]
        let rowBounds = rowMetric.touchFrame.union(rowMetric.nodeFrame)
        rowView.frame = rowBounds
        let offset = rowBounds.origin
        rowView.nodeView.frame = rowMetric.nodeFrame.offsetBy(dx: -offset.x, dy: -offset.y)
        rowView.titleLabel.frame = rowMetric.titleFrame.offsetBy(dx: -offset.x, dy: -offset.y)
        if let subtitleLabel = rowView.subtitleLabel, let subtitleFrame = rowMetric.subtitleFrame {
          subtitleLabel.frame = subtitleFrame.offsetBy(dx: -offset.x, dy: -offset.y)
        }
        if let timestampLabel = rowView.timestampLabel, let timestampFrame = rowMetric.timestampFrame {
          timestampLabel.frame = timestampFrame.offsetBy(dx: -offset.x, dy: -offset.y)
        }
        if let captionLabel = rowView.captionLabel, let captionFrame = rowMetric.captionFrame {
          captionLabel.frame = captionFrame.offsetBy(dx: -offset.x, dy: -offset.y)
        }
        if let chevronView = rowView.chevronView {
          chevronView.frame = CGRect(
            x: rowMetric.titleFrame.maxX - offset.x - 16,
            y: rowMetric.titleFrame.minY - offset.y,
            width: 12,
            height: 12
          )
        }

        if let connectorFrame = rowMetric.connectorFrame, connectorIndex < connectorLayers.count {
          let layer = connectorLayers[connectorIndex]
          layer.isHidden = false
          let item = flatItems[rowIndex]
          let completed = connectorIsCompleted(from: item)
          var style = configuration.appearance.connector
          if isTailConnector(sectionIndex: sectionIndex, rowMetric: rowMetric) {
            style.dashPattern = tailDashPattern()
          }
          layer.apply(style: style, completed: completed)
          layer.frame = connectorFrame
          layer.updatePath(
            from: CGPoint(x: layer.bounds.midX, y: 0),
            to: CGPoint(x: layer.bounds.midX, y: layer.bounds.height),
            animated: false,
            duration: 0
          )
          layer.setHiddenFromAccessibility(configuration.accessibility.hidesConnectorsFromAccessibility)
          connectorIndex += 1
        }
        rowIndex += 1
      }
    }

    for index in connectorIndex ..< connectorLayers.count {
      connectorLayers[index].isHidden = true
    }
    if sectionLabels.count > displaySections.count {
      for index in displaySections.count ..< sectionLabels.count {
        removeSectionLabelIfNeeded(at: index)
      }
      sectionLabels.removeLast(sectionLabels.count - displaySections.count)
    }
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
    scrollView.showsVerticalScrollIndicator = configuration.layout.scrollable
    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  private func applyConfigurationChange() {
    scrollView.showsVerticalScrollIndicator = configuration.layout.scrollable
    reconcileSubviews()
    applyItemsChange()
  }

  private func applyItemsChange() {
    displaySections = sections.isEmpty ? [FKTimelineSection(id: "default", title: "", items: items)] : sections
    flatItems = displaySections.flatMap(\.items)
    let validItemIDs = Set(flatItems.map(\.id))
    expandedItemIDs = expandedItemIDs.intersection(validItemIDs)
    reconcileSubviews()
    refreshPresentation()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateContainerAccessibility()
  }

  private func reconcileSubviews() {
    while rowViews.count < flatItems.count {
      let row = FKTimelineRowView()
      row.onTap = { [weak self] id in
        self?.handleRowTap(id: id)
      }
      rowViews.append(row)
      contentView.addSubview(row)
    }
    while rowViews.count > flatItems.count {
      rowViews.removeLast().removeFromSuperview()
    }

    while sectionLabels.count < displaySections.count {
      sectionLabels.append(nil)
    }
    while sectionLabels.count > displaySections.count {
      let index = sectionLabels.count - 1
      removeSectionLabelIfNeeded(at: index)
      sectionLabels.removeLast()
    }

    for (index, section) in displaySections.enumerated() {
      if section.title.isEmpty {
        removeSectionLabelIfNeeded(at: index)
      } else if let label = sectionLabels[index] {
        label.font = configuration.layout.sectionTitleFont
        label.textColor = configuration.layout.sectionTitleColor
      }
    }

    let connectorCount = max(0, flatItems.count - 1) + (configuration.layout.tailStyle == .none ? 0 : 1)
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
    for (index, item) in flatItems.enumerated() where index < rowViews.count {
      let showsChevron = configuration.interaction.allowsExpansion && !(item.caption?.isEmpty ?? true)
      let isSelectable = configuration.interaction.allowsSelection
        && (item.isInteractive ?? configuration.interaction.selectableStates.contains(item.state))
      let isInteractive = isSelectable || showsChevron
      rowViews[index].apply(
        item: item,
        stepIndex: index,
        configuration: configuration,
        isExpanded: expandedItemIDs.contains(item.id),
        showsChevron: showsChevron,
        isInteractive: isInteractive
      )
      rowViews[index].isUserInteractionEnabled = isInteractive
      rowViews[index].gestureRecognizers?.forEach { $0.isEnabled = isInteractive }
    }
  }

  private func updateContainerAccessibility() {
    isAccessibilityElement = false
    accessibilityElements = rowViews
    if let custom = configuration.accessibility.customLabel {
      accessibilityLabel = custom
    }
  }

  private func ensureSectionLabel(at index: Int) -> UILabel {
    if let label = sectionLabels[index] {
      return label
    }
    let label = UILabel()
    label.numberOfLines = 1
    label.font = configuration.layout.sectionTitleFont
    label.textColor = configuration.layout.sectionTitleColor
    contentView.addSubview(label)
    sectionLabels[index] = label
    return label
  }

  private func removeSectionLabelIfNeeded(at index: Int) {
    guard index < sectionLabels.count else { return }
    sectionLabels[index]?.removeFromSuperview()
    sectionLabels[index] = nil
  }

  private func handleRowTap(id: String) {
    guard let index = flatItems.firstIndex(where: { $0.id == id }) else { return }
    let item = flatItems[index]

    if configuration.interaction.allowsExpansion, !(item.caption?.isEmpty ?? true) {
      if expandedItemIDs.contains(id) {
        expandedItemIDs.remove(id)
      } else {
        expandedItemIDs.insert(id)
      }
      refreshPresentation()
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      return
    }

    guard configuration.interaction.allowsSelection else { return }
    let selectable = item.isInteractive ?? configuration.interaction.selectableStates.contains(item.state)
    guard selectable else { return }
    guard delegate?.timeline(self, shouldSelectItemAt: index) ?? true else { return }

    if configuration.interaction.hapticOnSelect {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    delegate?.timeline(self, didSelectItemAt: index)
    onItemSelected?(index, item)
  }

  private func connectorIsCompleted(from item: FKFlowStepItem) -> Bool {
    if item.state == .completed { return true }
    if item.state == .skipped, configuration.appearance.treatsSkippedAsCompletedForConnectors { return true }
    if item.state == .current { return true }
    return false
  }

  private func isTailConnector(sectionIndex: Int, rowMetric: FKTimelineLayoutEngine.RowMetrics) -> Bool {
    guard configuration.layout.tailStyle != .none else { return false }
    guard sectionIndex == displaySections.count - 1 else { return false }
    guard let lastRow = latestMetrics.sections.last?.rows.last else { return false }
    return lastRow.itemID == rowMetric.itemID
  }

  private func tailDashPattern() -> [CGFloat]? {
    switch configuration.layout.tailStyle {
    case .none: return nil
    case .dotted: return [2, 4]
    case .toFuture: return [4, 4]
    }
  }

  private func scrollVerticallyToCenter(_ frameInContentView: CGRect, animated: Bool) {
    let targetRect = contentView.convert(frameInContentView, to: scrollView)
    let centeredOffsetY = targetRect.midY - scrollView.bounds.height * 0.5
    let maxOffsetY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
    let clampedOffsetY = min(max(0, centeredOffsetY), maxOffsetY)
    scrollView.setContentOffset(CGPoint(x: 0, y: clampedOffsetY), animated: animated)
  }

  private func scrollAncestorToReveal(_ frameInContentView: CGRect, animated: Bool) {
    var view: UIView? = superview
    while let ancestor = view {
      if let scrollView = ancestor as? UIScrollView, scrollView !== self.scrollView {
        let targetRect = contentView.convert(frameInContentView, to: scrollView).insetBy(dx: 0, dy: -32)
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

/// Optional delegate callbacks for ``FKTimeline`` selection.
@MainActor
public protocol FKTimelineDelegate: AnyObject {
  /// Return `false` to prevent selection at `index`.
  func timeline(_ timeline: FKTimeline, shouldSelectItemAt index: Int) -> Bool
  /// Called after a row is selected.
  func timeline(_ timeline: FKTimeline, didSelectItemAt index: Int)
}

extension FKTimelineDelegate {
  public func timeline(_ timeline: FKTimeline, shouldSelectItemAt index: Int) -> Bool {
    true
  }

  public func timeline(_ timeline: FKTimeline, didSelectItemAt index: Int) {}
}
