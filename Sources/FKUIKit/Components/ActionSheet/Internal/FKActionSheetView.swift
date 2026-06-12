import UIKit

/// Callbacks from the grouped table that renders action rows.
@MainActor
protocol FKActionSheetViewDelegate: AnyObject {
  func actionSheetView(_ view: FKActionSheetView, didSelect action: FKActionSheetAction, sectionID: UUID?, isCancelGroup: Bool)
  func actionSheetView(_ view: FKActionSheetView, didToggle action: FKActionSheetAction, isOn: Bool)
}

/// UITableView-backed action list (header, sections, cancel group).
@MainActor
final class FKActionSheetView: UIView {
  weak var delegate: FKActionSheetViewDelegate?

  private(set) var currentConfiguration = FKActionSheetConfiguration()
  private var sectionKinds: [SectionKind] = []
  private var registeredReuseIdentifiers: Set<String> = []
  private var lastMeasuredWidth: CGFloat = -1
  private var cachedContentHeight: CGFloat?
  private var bottomSafeAreaFooterHeight: CGFloat = 0
  private var bottomSafeAreaFooterView: UIView?

  private var tableView: UITableView?
  private var tableViewConstraints: [NSLayoutConstraint] = []
  private var loadingHostView: FKActionSheetLoadingHostView?

  private var loadingHostConstraints: [NSLayoutConstraint] = []
  private var cachedTextHeaderView: FKActionSheetTextHeaderView?
  private var cachedCustomHeaderView: FKActionSheetCustomHeaderView?
  private var cachedSectionTitleViews: [String: FKActionSheetSectionTitleView] = [:]

  private enum SectionKind {
    case header(FKActionSheetHeaderContent)
    case actions(FKActionSheetSection)
    case cancel(FKActionSheetAction)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
  }

  /// Whether the table has a non-zero size and content height for selection scrolling.
  var isReadyForSelectionScroll: Bool {
    guard !isLoadingPresentationActive, let tableView else { return false }
    return bounds.height > 0 && tableView.contentSize.height > 0
  }

  private var isLoadingPresentationActive: Bool {
    currentConfiguration.isLoadingContentActive
  }

  /// Enables scrolling when content exceeds the presented sheet height cap.
  func setScrollEnabled(_ isEnabled: Bool) {
    guard let tableView else { return }
    tableView.isScrollEnabled = isEnabled
    tableView.alwaysBounceVertical = isEnabled
    tableView.showsVerticalScrollIndicator = isEnabled
  }

  /// Scrolls so the first selected row in table order is near the vertical center of the visible list.
  ///
  /// Uses the row’s layout rect and clamps ``contentOffset`` to valid bounds, so edge rows stay as
  /// centered as possible without leaving the list (best effort, not a hard guarantee).
  ///
  /// - Returns: `true` when scrolling was applied.
  @discardableResult
  func scrollToRevealSelection(animated: Bool) -> Bool {
    guard let tableView, tableView.isScrollEnabled else { return false }
    guard
      let actionID = currentConfiguration.selection.scrollTargetActionIDInTableOrder(
        sections: currentConfiguration.sections
      ),
      let indexPath = indexPath(forActionID: actionID)
    else {
      return false
    }

    tableView.layoutIfNeeded()

    // Materialize the row rect when the cell has not been displayed yet.
    if tableView.cellForRow(at: indexPath) == nil {
      tableView.scrollToRow(at: indexPath, at: .none, animated: false)
      tableView.layoutIfNeeded()
    }

    let rowRect = tableView.rectForRow(at: indexPath)
    guard rowRect.height > 0 else { return false }

    let topInset = tableView.adjustedContentInset.top
    let bottomInset = tableView.adjustedContentInset.bottom
    let visibleHeight = tableView.bounds.height - topInset - bottomInset
    guard visibleHeight > 0 else { return false }

    // Align the row midpoint with the midpoint of the visible viewport (content coordinates).
    let rowMidY = rowRect.midY
    let desiredOffsetY = rowMidY - topInset - visibleHeight / 2
    let minOffsetY = -topInset
    let maxOffsetY = max(
      minOffsetY,
      tableView.contentSize.height + bottomInset - tableView.bounds.height
    )
    let clampedOffsetY = min(max(desiredOffsetY, minOffsetY), maxOffsetY)

    guard abs(tableView.contentOffset.y - clampedOffsetY) > 0.5 else { return true }
    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: clampedOffsetY), animated: animated)
    return true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(configuration: FKActionSheetConfiguration) {
    currentConfiguration = configuration
    invalidateMeasurementCache()
    rebuildSectionKinds()
    backgroundColor = currentConfiguration.appearance.backgroundColor
    bottomSafeAreaFooterView?.backgroundColor = currentConfiguration.appearance.backgroundColor

    if isLoadingPresentationActive, let loadingConfiguration = configuration.loadingConfiguration {
      removeTableViewIfNeeded()
      let host = ensureLoadingHostView()
      host.updateBottomSafeAreaInset(bottomSafeAreaFooterHeight)
      host.apply(
        loadingConfiguration: loadingConfiguration,
        appearance: configuration.appearance,
        cancelAction: configuration.cancelAction,
        layoutWidth: max(1, bounds.width)
      )
    } else {
      removeLoadingHostIfNeeded()
      let tableView = ensureTableView()
      tableView.backgroundColor = currentConfiguration.appearance.backgroundColor
      tableView.estimatedRowHeight = configuration.appearance.minimumRowHeight
      applySeparatorStyle(on: tableView)
      registerCustomRowReuseIdentifiers()
      tableView.reloadData()
      if bottomSafeAreaFooterHeight > 0 {
        applyBottomSafeAreaFooter(height: bottomSafeAreaFooterHeight)
      }
    }
    setNeedsLayout()
  }

  /// Updates selection accessories without a full table reload.
  func syncSelectionConfiguration(_ configuration: FKActionSheetConfiguration) {
    currentConfiguration = configuration
    rebuildSectionKinds()
    guard let tableView else { return }
    let indexPaths = indexPathsInSelectionScope(for: configuration.selection)
    guard !indexPaths.isEmpty else { return }
    tableView.reloadRows(at: indexPaths, with: .none)
  }

  /// Preferred accessibility focus after present when a selection row is restored.
  func accessibilityElementToFocus() -> Any? {
    if isLoadingPresentationActive {
      return loadingHostView?.accessibilityElementToFocus()
    }
    guard
      let tableView,
      let actionID = currentConfiguration.selection.scrollTargetActionIDInTableOrder(
        sections: currentConfiguration.sections
      ),
      let indexPath = indexPath(forActionID: actionID)
    else {
      return nil
    }
    tableView.layoutIfNeeded()
    return tableView.cellForRow(at: indexPath)
  }

  /// Updates a single row in place without reloading the full table when possible.
  func refreshAction(_ action: FKActionSheetAction) {
    guard let tableView else { return }
    guard replaceStoredAction(action) else { return }
    invalidateMeasurementCache()
    rebuildSectionKinds()
    guard let indexPath = indexPath(forActionID: action.id) else {
      apply(configuration: currentConfiguration)
      return
    }
    if case .toggle(let toggle) = action.rowContent,
       let cell = tableView.cellForRow(at: indexPath) as? FKActionSheetToggleCell
    {
      cell.setToggleOn(toggle.isOn, animated: true)
      return
    }
    tableView.reloadRows(at: [indexPath], with: .none)
  }

  /// Reserves space below the last row for the home indicator via `tableFooterView`.
  ///
  /// A footer works when scrolling is disabled; `contentInset.bottom` alone does not lift rows.
  func updateBottomSafeAreaInset(_ inset: CGFloat) {
    let bottom = max(0, inset)
    guard abs(bottomSafeAreaFooterHeight - bottom) > 0.5 else { return }
    bottomSafeAreaFooterHeight = bottom
    if isLoadingPresentationActive {
      loadingHostView?.updateBottomSafeAreaInset(bottom)
      return
    }
    let tableView = ensureTableView()
    if tableView.contentInset.bottom > 0 {
      var contentInset = tableView.contentInset
      contentInset.bottom = 0
      tableView.contentInset = contentInset
    }
    applyBottomSafeAreaFooter(height: bottom)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateBottomSafeAreaFooterFrameIfNeeded()
    if isLoadingPresentationActive {
      loadingHostView?.updateLayoutIfNeeded(layoutWidth: max(1, bounds.width))
    }
  }

  @discardableResult
  private func ensureLoadingHostView() -> FKActionSheetLoadingHostView {
    if let loadingHostView {
      return loadingHostView
    }
    let view = FKActionSheetLoadingHostView()
    view.delegate = self
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    let constraints = [
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
    loadingHostConstraints = constraints
    loadingHostView = view
    return view
  }

  private func removeLoadingHostIfNeeded() {
    guard let host = loadingHostView else { return }
    host.teardownContent()
    host.removeFromSuperview()
    NSLayoutConstraint.deactivate(loadingHostConstraints)
    loadingHostConstraints = []
    loadingHostView = nil
  }

  @discardableResult
  private func ensureTableView() -> UITableView {
    if let tableView {
      return tableView
    }

    let table = UITableView(frame: .zero, style: .plain)
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.sectionHeaderTopPadding = 0
    table.dataSource = self
    table.delegate = self
    table.register(FKActionSheetActionCell.self, forCellReuseIdentifier: FKActionSheetActionCell.reuseIdentifier)
    table.register(
      FKActionSheetCustomRowCell.self,
      forCellReuseIdentifier: FKActionSheetCustomRowCell.defaultReuseIdentifier
    )
    table.register(
      FKActionSheetToggleCell.self,
      forCellReuseIdentifier: FKActionSheetToggleCell.defaultReuseIdentifier
    )
    registeredReuseIdentifiers.insert(FKActionSheetCustomRowCell.defaultReuseIdentifier)
    registeredReuseIdentifiers.insert(FKActionSheetToggleCell.defaultReuseIdentifier)
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 48
    table.contentInsetAdjustmentBehavior = .never
    table.isScrollEnabled = false
    table.alwaysBounceVertical = false
    table.showsVerticalScrollIndicator = false

    addSubview(table)
    let constraints = [
      table.topAnchor.constraint(equalTo: topAnchor),
      table.leadingAnchor.constraint(equalTo: leadingAnchor),
      table.trailingAnchor.constraint(equalTo: trailingAnchor),
      table.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
    tableViewConstraints = constraints
    tableView = table
    return table
  }

  private func removeTableViewIfNeeded() {
    guard let table = tableView else { return }
    table.dataSource = nil
    table.delegate = nil
    table.removeFromSuperview()
    NSLayoutConstraint.deactivate(tableViewConstraints)
    tableViewConstraints = []
    bottomSafeAreaFooterView = nil
    registeredReuseIdentifiers.removeAll()
    clearHeaderViewCache()
    tableView = nil
  }

  private func clearHeaderViewCache() {
    cachedTextHeaderView = nil
    cachedCustomHeaderView = nil
    cachedSectionTitleViews.removeAll()
  }

  private func applyBottomSafeAreaFooter(height: CGFloat) {
    guard let tableView else { return }
    guard height > 0 else {
      bottomSafeAreaFooterView = nil
      tableView.tableFooterView = nil
      return
    }
    let width = max(tableView.bounds.width, bounds.width, 1)
    let footer = bottomSafeAreaFooterView ?? UIView()
    footer.backgroundColor = currentConfiguration.appearance.backgroundColor
    footer.isUserInteractionEnabled = false
    footer.frame = CGRect(x: 0, y: 0, width: width, height: height)
    bottomSafeAreaFooterView = footer
    tableView.tableFooterView = footer
  }

  private func updateBottomSafeAreaFooterFrameIfNeeded() {
    guard bottomSafeAreaFooterHeight > 0, let tableView else { return }
    let width = max(tableView.bounds.width, bounds.width, 1)
    guard let footer = bottomSafeAreaFooterView else {
      applyBottomSafeAreaFooter(height: bottomSafeAreaFooterHeight)
      return
    }
    guard abs(footer.frame.width - width) > 0.5 || abs(footer.frame.height - bottomSafeAreaFooterHeight) > 0.5 else {
      return
    }
    footer.frame = CGRect(x: 0, y: 0, width: width, height: bottomSafeAreaFooterHeight)
    tableView.tableFooterView = footer
  }

  /// Measures the natural content height required to show all rows without scrolling.
  ///
  /// Uses deterministic row/header estimates to avoid `reloadData()` during layout
  /// (which can cause presentation ↔ content layout feedback loops on long lists).
  func measuredContentHeight(for width: CGFloat) -> CGFloat {
    let fittingWidth = max(width, 1)
    if isLoadingPresentationActive {
      return loadingHostView?.measuredContentHeight(for: fittingWidth)
        ?? currentConfiguration.appearance.minimumRowHeight
    }
    if fittingWidth == lastMeasuredWidth, let cachedContentHeight {
      return cachedContentHeight
    }

    let measured = max(ceil(estimatedContentHeight()), minimumMeasuredHeight)
    lastMeasuredWidth = fittingWidth
    cachedContentHeight = measured
    return measured
  }

  private func invalidateMeasurementCache() {
    lastMeasuredWidth = -1
    cachedContentHeight = nil
  }

  private var minimumMeasuredHeight: CGFloat {
    currentConfiguration.appearance.minimumRowHeight
  }

  /// Fallback height when Auto Layout fitting runs before cells are materialized.
  private func estimatedContentHeight() -> CGFloat {
    let appearance = currentConfiguration.appearance
    var total: CGFloat = 0

    for kind in sectionKinds {
      switch kind {
      case .header(let header):
        switch header {
        case .text(let textHeader):
          if !textHeader.isEmpty {
            total += 56
          }
        case .custom(let customHeader):
          total += resolvedCustomHeaderHeight(customHeader)
        }
      case .actions(let section):
        if let title = section.title, !title.isEmpty {
          total += 28
        }
        for action in section.actions {
          total += rowHeightEstimate(for: action, appearance: appearance)
        }
      case .cancel(let action):
        total += appearance.cancelGroupSpacing
        total += rowHeightEstimate(for: action, appearance: appearance)
      }
    }

    return max(total, appearance.minimumRowHeight)
  }

  private func rowHeightEstimate(for action: FKActionSheetAction, appearance: FKActionSheetAppearance) -> CGFloat {
    switch action.rowContent {
    case .custom(let row):
      return max(row.preferredHeight ?? appearance.minimumRowHeight, appearance.minimumRowHeight)
    case .standard:
      return estimatedStandardRowHeight(for: action, appearance: appearance)
    case .toggle:
      return appearance.minimumRowHeight
    }
  }

  private func estimatedStandardRowHeight(
    for action: FKActionSheetAction,
    appearance: FKActionSheetAppearance
  ) -> CGFloat {
    guard let subtitle = action.subtitle, !subtitle.isEmpty else {
      return appearance.minimumRowHeight
    }
    let subtitleLine = appearance.resolvedActionSubtitleFont().lineHeight
    return appearance.minimumRowHeight + subtitleLine + 4
  }

  private func usesAutomaticRowHeight(for action: FKActionSheetAction) -> Bool {
    switch action.rowContent {
    case .standard:
      if let subtitle = action.subtitle, !subtitle.isEmpty { return true }
      return false
    case .custom(let row):
      return row.preferredHeight == nil
    case .toggle:
      return false
    }
  }

  private func registerCustomRowReuseIdentifiers() {
    guard let tableView else { return }
    for action in currentConfiguration.allActions {
      switch action.rowContent {
      case .custom(let row):
        registerCustomRowReuseIdentifier(row.reuseIdentifier)
      case .toggle(let row):
        registerToggleRowReuseIdentifier(row.reuseIdentifier)
      case .standard:
        break
      }
    }
  }

  private func registerCustomRowReuseIdentifier(_ identifier: String) {
    guard let tableView else { return }
    guard !registeredReuseIdentifiers.contains(identifier) else { return }
    tableView.register(FKActionSheetCustomRowCell.self, forCellReuseIdentifier: identifier)
    registeredReuseIdentifiers.insert(identifier)
  }

  private func registerToggleRowReuseIdentifier(_ identifier: String) {
    guard let tableView else { return }
    guard !registeredReuseIdentifiers.contains(identifier) else { return }
    tableView.register(FKActionSheetToggleCell.self, forCellReuseIdentifier: identifier)
    registeredReuseIdentifiers.insert(identifier)
  }

  @discardableResult
  private func replaceStoredAction(_ action: FKActionSheetAction) -> Bool {
    var didReplace = false
    currentConfiguration.sections = currentConfiguration.sections.map { section in
      var copy = section
      copy.actions = section.actions.map { row in
        guard row.id == action.id else { return row }
        didReplace = true
        return action
      }
      return copy
    }
    if var cancel = currentConfiguration.cancelAction, cancel.id == action.id {
      currentConfiguration.cancelAction = action
      didReplace = true
    }
    return didReplace
  }

  private func indexPathsInSelectionScope(
    for selection: FKActionSheetSelectionConfiguration
  ) -> [IndexPath] {
    var paths: [IndexPath] = []
    for (sectionIndex, kind) in sectionKinds.enumerated() {
      guard case .actions(let model) = kind else { continue }
      let isInScope: Bool = {
        switch selection.mode {
        case .none:
          return false
        case .single(let scope):
          return scope.contains(sectionID: model.id)
        case .multiple(let multiple):
          return multiple.scope.contains(sectionID: model.id)
        }
      }()
      guard isInScope else { continue }
      paths.append(contentsOf: model.actions.indices.map { IndexPath(row: $0, section: sectionIndex) })
    }
    return paths
  }

  private func indexPath(forActionID actionID: UUID) -> IndexPath? {
    for (sectionIndex, kind) in sectionKinds.enumerated() {
      switch kind {
      case .actions(let model):
        if let row = model.actions.firstIndex(where: { $0.id == actionID }) {
          return IndexPath(row: row, section: sectionIndex)
        }
      case .cancel(let action):
        if action.id == actionID {
          return IndexPath(row: 0, section: sectionIndex)
        }
      case .header:
        break
      }
    }
    return nil
  }

  private func applySeparatorStyle(on tableView: UITableView) {
    switch currentConfiguration.appearance.separatorStyle {
    case .automatic:
      tableView.separatorStyle = .singleLine
    case .none:
      tableView.separatorStyle = .none
    case .singleLine:
      tableView.separatorStyle = .singleLine
    }
    tableView.separatorColor = currentConfiguration.appearance.separatorColor
  }

  private func rebuildSectionKinds() {
    sectionKinds = []
    if let header = currentConfiguration.header, !header.isEmpty {
      sectionKinds.append(.header(header))
    }
    for section in currentConfiguration.sections where !section.actions.isEmpty {
      sectionKinds.append(.actions(section))
    }
    if let cancelAction = currentConfiguration.cancelAction {
      sectionKinds.append(.cancel(cancelAction))
    }
  }

  private func rowContext(
    for action: FKActionSheetAction,
    sectionID: UUID?,
    isCancelGroup: Bool
  ) -> FKActionSheetRowBuildContext {
    FKActionSheetRowBuildContext(
      action: action,
      sectionID: sectionID,
      isCancelGroup: isCancelGroup,
      appearance: currentConfiguration.appearance,
      boundsWidth: max(1, bounds.width)
    )
  }
}

extension FKActionSheetView: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    sectionKinds.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch sectionKinds[section] {
    case .header:
      return 0
    case .actions(let model):
      return model.actions.count
    case .cancel:
      return 1
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let action = action(at: indexPath)
    let preferred: CGFloat? = {
      switch action.rowContent {
      case .custom(let row):
        return row.preferredHeight
      case .toggle:
        return nil
      case .standard:
        return nil
      }
    }()
    if usesAutomaticRowHeight(for: action) {
      return UITableView.automaticDimension
    }
    guard let preferred else {
      return currentConfiguration.appearance.minimumRowHeight
    }
    return max(preferred, currentConfiguration.appearance.minimumRowHeight)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let action = action(at: indexPath)
    let isCancel = isCancelSection(indexPath.section)
    let sectionID = sectionID(for: indexPath.section)

    switch action.rowContent {
    case .standard:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: FKActionSheetActionCell.reuseIdentifier,
        for: indexPath
      ) as! FKActionSheetActionCell
      cell.apply(
        action: action,
        appearance: currentConfiguration.appearance,
        isCancelGroup: isCancel,
        selectionIndicatorStyle: currentConfiguration.selection.indicatorStyle,
        selectionModeActive: isSelectionModeActive,
        isRowInteractionEnabled: currentConfiguration.selection.isRowInteractionEnabled(
          for: action,
          sectionID: sectionID,
          isCancelGroup: isCancel
        )
      )
      cell.backgroundColor = currentConfiguration.appearance.cellBackgroundColor
      return cell
    case .toggle(let toggle):
      let cell = tableView.dequeueReusableCell(
        withIdentifier: toggle.reuseIdentifier,
        for: indexPath
      ) as! FKActionSheetToggleCell
      cell.apply(
        action: action,
        toggle: toggle,
        appearance: currentConfiguration.appearance
      ) { [weak self] isOn in
        guard let self else { return }
        self.delegate?.actionSheetView(self, didToggle: action, isOn: isOn)
      }
      cell.backgroundColor = currentConfiguration.appearance.cellBackgroundColor
      return cell
    case .custom(let customRow):
      let cell = tableView.dequeueReusableCell(
        withIdentifier: customRow.reuseIdentifier,
        for: indexPath
      ) as! FKActionSheetCustomRowCell
      let context = rowContext(for: action, sectionID: sectionID, isCancelGroup: isCancel)
      cell.apply(
        action: action,
        customRow: customRow,
        context: context,
        appearance: currentConfiguration.appearance
      )
      cell.backgroundColor = currentConfiguration.appearance.cellBackgroundColor
      return cell
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    switch sectionKinds[section] {
    case .header(let header):
      return makeHeaderView(header: header)
    case .actions(let model):
      guard let title = model.title, !title.isEmpty else { return nil }
      return makeSectionTitleView(title: title)
    case .cancel:
      return nil
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    switch sectionKinds[section] {
    case .header(let header):
      switch header {
      case .text:
        return UITableView.automaticDimension
      case .custom(let custom):
        if let preferred = custom.preferredHeight {
          return resolvedCustomHeaderHeight(custom)
        }
        return UITableView.automaticDimension
      }
    case .actions(let model):
      return (model.title?.isEmpty == false) ? 28 : .leastNormalMagnitude
    case .cancel:
      return currentConfiguration.appearance.cancelGroupSpacing
    }
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    .leastNormalMagnitude
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let action = action(at: indexPath)
    if case .custom(let row) = action.rowContent, !row.isSelectable { return }
    switch sectionKinds[indexPath.section] {
    case .actions(let model):
      delegate?.actionSheetView(self, didSelect: action, sectionID: model.id, isCancelGroup: false)
    case .cancel:
      delegate?.actionSheetView(self, didSelect: action, sectionID: nil, isCancelGroup: true)
    case .header:
      break
    }
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if isCancelSection(indexPath.section) {
      // Cancel is the bottom-most row; hide the trailing separator (system action sheets omit it).
      cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
      return
    }
    let inset = currentConfiguration.appearance.rowHorizontalPadding
    cell.separatorInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
  }

  private func action(at indexPath: IndexPath) -> FKActionSheetAction {
    switch sectionKinds[indexPath.section] {
    case .actions(let model):
      return model.actions[indexPath.row]
    case .cancel(let action):
      return action
    case .header:
      fatalError("Header sections do not have rows.")
    }
  }

  private func sectionID(for section: Int) -> UUID? {
    if case .actions(let model) = sectionKinds[section] {
      return model.id
    }
    return nil
  }

  private func isCancelSection(_ section: Int) -> Bool {
    if case .cancel = sectionKinds[section] { return true }
    return false
  }

  /// Whether selection accessories and selection interaction rules are active.
  private var isSelectionModeActive: Bool {
    currentConfiguration.selection.isSelectionActive
  }

  private func resolvedCustomHeaderHeight(_ header: FKActionSheetCustomHeader) -> CGFloat {
    header.preferredHeight ?? 72
  }

  private func makeHeaderView(header: FKActionSheetHeaderContent) -> UIView {
    switch header {
    case .text(let textHeader):
      let view = cachedTextHeaderView ?? FKActionSheetTextHeaderView(frame: .zero)
      cachedTextHeaderView = view
      view.apply(header: textHeader, appearance: currentConfiguration.appearance)
      return view
    case .custom(let customHeader):
      let view = cachedCustomHeaderView ?? FKActionSheetCustomHeaderView(frame: .zero)
      cachedCustomHeaderView = view
      let context = FKActionSheetHeaderBuildContext(
        appearance: currentConfiguration.appearance,
        boundsWidth: max(1, bounds.width)
      )
      view.apply(header: customHeader, context: context)
      return view
    }
  }

  private func makeSectionTitleView(title: String) -> UIView {
    let key = title.uppercased()
    let view = cachedSectionTitleViews[key] ?? FKActionSheetSectionTitleView(frame: .zero)
    cachedSectionTitleViews[key] = view
    view.apply(title: title, appearance: currentConfiguration.appearance)
    return view
  }
}

extension FKActionSheetView: FKActionSheetLoadingHostViewDelegate {
  func loadingHostView(_ view: FKActionSheetLoadingHostView, didSelectCancel action: FKActionSheetAction) {
    delegate?.actionSheetView(self, didSelect: action, sectionID: nil, isCancelGroup: true)
  }
}
