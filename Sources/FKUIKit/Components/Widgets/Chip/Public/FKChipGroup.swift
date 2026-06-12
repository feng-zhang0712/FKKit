import UIKit

/// Lays out ``FKChip`` instances with optional selection orchestration.
@MainActor
public final class FKChipGroup: UIView {
  public static var defaultConfiguration: FKChipGroupConfiguration {
    get { FKChipGroupDefaults.configuration }
    set { FKChipGroupDefaults.configuration = newValue }
  }

  public var configuration: FKChipGroupConfiguration = FKChipGroup.defaultConfiguration {
    didSet { reloadChips() }
  }

  public var chips: [FKChipItem] = [] {
    didSet { reloadChips() }
  }

  public var selectionMode: FKChipGroupSelectionMode = .none {
    didSet {
      guard oldValue != selectionMode else { return }
      applySelectionModeToChips()
      syncSelectionFromItems()
    }
  }

  public private(set) var selectedIDs: Set<String> = []

  public var onSelectionChange: ((Set<String>) -> Void)?
  public var onSelectionLimitReached: (() -> Void)?
  /// Fires with the tapped chip id when a child emits ``UIControl/Event/primaryActionTriggered`` (for example ``FKChipMode/suggestion``).
  public var onChipPrimaryAction: ((String) -> Void)?
  /// Fires with the removed chip id when the user taps a remove affordance in ``FKChipMode/input`` (or any chip with ``FKChipItem/showsRemoveButton``).
  public var onChipRemoved: ((String) -> Void)?

  var flowContainer: FKFlowLayoutView?
  var scrollView: UIScrollView?
  var scrollContentView: FKFlowLayoutView?
  private var chipViews: [String: FKChip] = [:]
  private var isApplyingExternalSelection = false
  private var needsInitialSelectionScroll = false
  private var lastFlowLayoutWidth: CGFloat = 0

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKChipGroupConfiguration = FKChipGroup.defaultConfiguration,
    chips: [FKChipItem] = [],
    selectionMode: FKChipGroupSelectionMode = .none
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.selectionMode = selectionMode
    self.chips = chips
    reloadChips()
  }

  public override var intrinsicContentSize: CGSize {
    measuredIntrinsicSize()
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    measuredIntrinsicSize(proposedWidth: size.width > 0 ? size.width : nil)
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    refreshFlowLayoutMeasurement()
    invalidateIntrinsicContentSize()
  }

  public override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    switch configuration.layoutMode {
    case .flow:
      guard let flowContainer else { return }
      flowContainer.frame = bounds
      guard bounds.width > 0 else { return }
      let size = flowContainer.applyLayout(maxWidth: bounds.width)
      let widthChanged = abs(bounds.width - lastFlowLayoutWidth) > 0.5
      let heightChanged = abs(size.height - bounds.height) > 0.5
      if widthChanged || heightChanged {
        lastFlowLayoutWidth = bounds.width
        invalidateIntrinsicContentSize()
      }
    case .horizontalScroll:
      guard let scrollView, let scrollContentView else { return }
      scrollContentView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
      scrollContentView.layoutIfNeeded()
      let naturalWidth = scrollContentView.laidOutSize.width
      let contentOverflows = naturalWidth > bounds.width + 0.5
      let peek = contentOverflows ? max(0, configuration.horizontalScrollTrailingPeek) : 0
      let viewportWidth = max(1, bounds.width - peek)
      scrollView.frame = CGRect(x: 0, y: 0, width: viewportWidth, height: bounds.height)
      let contentWidth = max(naturalWidth, viewportWidth)
      scrollContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: bounds.height)
      scrollView.contentSize = CGSize(width: contentWidth, height: bounds.height)
      if needsInitialSelectionScroll {
        needsInitialSelectionScroll = false
        scrollToRevealSelection(animated: false)
      }
    }
  }

  /// Programmatically updates selection without emitting ``onSelectionChange``.
  public func setSelectedIDs(_ ids: Set<String>, animated: Bool) {
    isApplyingExternalSelection = true
    defer { isApplyingExternalSelection = false }
    selectedIDs = ids
    syncChipSelectionStates(animated: animated)
    updateGroupAccessibility()
    scrollToRevealSelection(animated: animated)
  }

  private func commonInit() {
    accessibilityContainerType = .semanticGroup
    clipsToBounds = true
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)
    reloadChips()
  }

  private func measuredIntrinsicSize(proposedWidth: CGFloat? = nil) -> CGSize {
    let chipHeight = configuration.chipConfiguration.layout.size.height
    switch configuration.layoutMode {
    case .flow:
      let width = proposedWidth ?? proposedLayoutWidth()
      guard width > 0, let flowContainer else {
        return CGSize(
          width: UIView.noIntrinsicMetric,
          height: chips.isEmpty ? 0 : chipHeight
        )
      }
      let size = flowContainer.measureLayout(maxWidth: width)
      return CGSize(
        width: UIView.noIntrinsicMetric,
        height: max(size.height, chips.isEmpty ? 0 : chipHeight)
      )
    case .horizontalScroll:
      return CGSize(width: UIView.noIntrinsicMetric, height: chipHeight)
    }
  }

  private func proposedLayoutWidth() -> CGFloat {
    if bounds.width > 0 { return bounds.width }

    var candidate: UIView? = superview
    while let host = candidate {
      if host.bounds.width > 0 { return host.bounds.width }
      let marginWidth = host.layoutMarginsGuide.layoutFrame.width
      if marginWidth > 0 { return marginWidth }
      candidate = host.superview
    }
    return 0
  }

  private func refreshFlowLayoutMeasurement() {
    guard case .flow = configuration.layoutMode, let flowContainer else { return }
    let width = proposedLayoutWidth()
    guard width > 0 else { return }
    flowContainer.applyLayout(maxWidth: width)
  }

  private func reloadChips() {
    let existing = chipViews
    chipViews.removeAll()

    for chip in existing.values {
      chip.removeFromSuperview()
    }

    syncLayoutContainers()
    applyLayoutContainerConfiguration()

    let container = activeChipContainer()
    syncSelectedIDsFromChipItems()

    for item in chips {
      let chip: FKChip
      if let reused = existing[item.id] {
        chip = reused
      } else {
        chip = FKChip(configuration: configuration.chipConfiguration, mode: configuration.chipMode, title: item.title)
        chip.addAction(UIAction { [weak self, weak chip] _ in
          guard let self, let chip else { return }
          self.handleChipInteraction(id: item.id, chip: chip)
        }, for: .valueChanged)
        chip.addAction(UIAction { [weak self] _ in
          self?.handleChipPrimaryAction(id: item.id)
        }, for: .primaryActionTriggered)
      }

      chip.mode = configuration.chipMode
      chip.configuration = configuration.chipConfiguration
      chip.managesSelectionInternally = selectionMode == .none
      chip.applyContent(
        title: item.title,
        icon: item.leadingIcon,
        selected: selectedIDs.contains(item.id),
        enabled: item.isEnabled,
        showsRemove: item.showsRemoveButton
      )
      chip.onRemove = { [weak self] in
        self?.handleRemove(id: item.id)
      }
      chipViews[item.id] = chip
      container.addSubview(chip)
    }

    syncChipSelectionStates(animated: false)
    updateGroupAccessibility()
    refreshFlowLayoutMeasurement()
    invalidateIntrinsicContentSize()
    needsInitialSelectionScroll = configuration.scrollsToSelectedChip
      && configuration.layoutMode == .horizontalScroll
      && !selectedIDs.isEmpty
    lastFlowLayoutWidth = 0
    setNeedsLayout()
    superview?.setNeedsLayout()
  }

  private func syncSelectionFromItems() {
    syncSelectedIDsFromChipItems()
    syncChipSelectionStates(animated: false)
  }

  /// Merges ``FKChipItem/isSelected`` flags with the current selection, dropping ids that no longer exist.
  private func syncSelectedIDsFromChipItems() {
    let chipIDs = Set(chips.map(\.id))
    let explicitSelection = Set(chips.filter(\.isSelected).map(\.id))
    if chips.contains(where: \.isSelected) {
      selectedIDs = explicitSelection
    } else {
      selectedIDs = selectedIDs.intersection(chipIDs)
    }
  }

  private func applySelectionModeToChips() {
    let managesInternally = selectionMode == .none
    for chip in chipViews.values {
      chip.managesSelectionInternally = managesInternally
    }
  }

  private func syncChipSelectionStates(animated: Bool) {
    for item in chips {
      guard let chip = chipViews[item.id] else { continue }
      let selected = selectedIDs.contains(item.id)
      if chip.isSelected != selected {
        if animated {
          UIView.animate(withDuration: 0.15) { chip.isSelected = selected }
        } else {
          chip.isSelected = selected
        }
      }
    }
  }

  private func handleChipInteraction(id: String, chip: FKChip) {
    guard configuration.chipMode == .filter || configuration.chipMode == .choice else { return }
    switch selectionMode {
    case .none:
      if !isApplyingExternalSelection {
        onSelectionChange?(Set(chips.filter { chipViews[$0.id]?.isSelected == true }.map(\.id)))
      }
      if chip.isSelected {
        scrollToRevealSelection(animated: true, preferredID: id)
      }
    case .single, .multiple:
      let result = FKChipGroupSelectionController.toggledSelection(
        current: selectedIDs,
        tappedID: id,
        mode: selectionMode,
        overflowBehavior: configuration.overflowBehavior
      )
      if result.limitReached {
        onSelectionLimitReached?()
        chip.isSelected = selectedIDs.contains(id)
        return
      }
      selectedIDs = result.selection
      syncChipSelectionStates(animated: true)
      if !isApplyingExternalSelection {
        onSelectionChange?(selectedIDs)
      }
      scrollToRevealSelection(animated: true, preferredID: id)
    }
    updateGroupAccessibility()
  }

  private func handleChipPrimaryAction(id: String) {
    onChipPrimaryAction?(id)
    if configuration.chipMode == .suggestion, !isApplyingExternalSelection {
      onSelectionChange?(selectedIDs)
    }
  }

  private func handleRemove(id: String) {
    chips.removeAll { $0.id == id }
    selectedIDs.remove(id)
    onChipRemoved?(id)
    onSelectionChange?(selectedIDs)
  }

  private func updateGroupAccessibility() {
    switch selectionMode {
    case .multiple:
      accessibilityLabel = FKChipI18n.groupSelectionCount(selectedIDs.count)
    default:
      accessibilityLabel = nil
    }
  }

  /// Scrolls the horizontal rail so `preferredID` (or the first selected chip) is fully visible.
  private func scrollToRevealSelection(animated: Bool, preferredID: String? = nil) {
    guard configuration.scrollsToSelectedChip,
          case .horizontalScroll = configuration.layoutMode,
          let scrollView,
          let scrollContentView else { return }

    let targetID = preferredID ?? chips.first(where: { selectedIDs.contains($0.id) })?.id
    guard let targetID, let chip = chipViews[targetID] else { return }

    scrollView.layoutIfNeeded()
    scrollContentView.layoutIfNeeded()

    let chipFrame = chip.frame
    guard chipFrame.width > 0 else { return }

    let padding = configuration.itemSpacing
    let visibleMinX = scrollView.contentOffset.x
    let visibleMaxX = visibleMinX + scrollView.bounds.width
    let targetMinX = chipFrame.minX - padding
    let targetMaxX = chipFrame.maxX + padding

    guard targetMinX < visibleMinX || targetMaxX > visibleMaxX else { return }

    var offset = scrollView.contentOffset
    if targetMinX < visibleMinX {
      offset.x = targetMinX
    } else {
      let peek = max(0, configuration.horizontalScrollTrailingPeek)
      let hasTrailingContent = targetMaxX + peek < scrollView.contentSize.width - configuration.contentInsets.right
      offset.x = targetMaxX - scrollView.bounds.width + (hasTrailingContent ? peek : 0)
    }

    let minOffsetX = -scrollView.adjustedContentInset.left
    let maxOffsetX = max(
      minOffsetX,
      scrollView.contentSize.width - scrollView.bounds.width + scrollView.adjustedContentInset.right
    )
    offset.x = min(max(offset.x, minOffsetX), maxOffsetX)
    scrollView.setContentOffset(offset, animated: animated)
  }
}
