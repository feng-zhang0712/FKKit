import UIKit

@MainActor
protocol FKActionSheetViewDelegate: AnyObject {
  func actionSheetView(_ view: FKActionSheetView, didSelect action: FKActionSheetAction, sectionID: UUID?, isCancelGroup: Bool)
  func actionSheetView(_ view: FKActionSheetView, didToggle action: FKActionSheetAction, isOn: Bool)
}

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

  private enum SectionKind {
    case header(FKActionSheetHeaderContent)
    case actions(FKActionSheetSection)
    case cancel(FKActionSheetAction)
  }

  private lazy var tableView: UITableView = {
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
    return table
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: topAnchor),
      tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    tableView.isScrollEnabled = false
    tableView.alwaysBounceVertical = false
    tableView.showsVerticalScrollIndicator = false
  }

  /// Enables scrolling when content exceeds the presented sheet height cap.
  func setScrollEnabled(_ isEnabled: Bool) {
    tableView.isScrollEnabled = isEnabled
    tableView.alwaysBounceVertical = isEnabled
    tableView.showsVerticalScrollIndicator = isEnabled
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(configuration: FKActionSheetConfiguration) {
    currentConfiguration = configuration
    invalidateMeasurementCache()
    registerCustomRowReuseIdentifiers()
    rebuildSectionKinds()
    backgroundColor = currentConfiguration.appearance.backgroundColor
    tableView.backgroundColor = currentConfiguration.appearance.backgroundColor
    bottomSafeAreaFooterView?.backgroundColor = currentConfiguration.appearance.backgroundColor
    applySeparatorStyle()
    tableView.estimatedRowHeight = configuration.appearance.minimumRowHeight
    tableView.reloadData()
    if bottomSafeAreaFooterHeight > 0 {
      applyBottomSafeAreaFooter(height: bottomSafeAreaFooterHeight)
    }
    setNeedsLayout()
  }

  /// Updates a single row in place without reloading the full table when possible.
  func refreshAction(_ action: FKActionSheetAction) {
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
      cell.setToggleOn(toggle.isOn, animated: false)
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
  }

  private func applyBottomSafeAreaFooter(height: CGFloat) {
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
    guard bottomSafeAreaFooterHeight > 0 else { return }
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
    guard !registeredReuseIdentifiers.contains(identifier) else { return }
    tableView.register(FKActionSheetCustomRowCell.self, forCellReuseIdentifier: identifier)
    registeredReuseIdentifiers.insert(identifier)
  }

  private func registerToggleRowReuseIdentifier(_ identifier: String) {
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

  private func applySeparatorStyle() {
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
        selectionModeActive: usesSelectionAccessory
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

  private var usesSelectionAccessory: Bool {
    switch currentConfiguration.selection.mode {
    case .none:
      return false
    case .single:
      return true
    }
  }

  private func resolvedCustomHeaderHeight(_ header: FKActionSheetCustomHeader) -> CGFloat {
    header.preferredHeight ?? 72
  }

  private func minimumRowHeight(for action: FKActionSheetAction) -> CGFloat {
    let appearance = currentConfiguration.appearance
    switch action.rowContent {
    case .custom(let row):
      return max(row.preferredHeight ?? appearance.minimumRowHeight, appearance.minimumRowHeight)
    case .standard:
      return estimatedStandardRowHeight(for: action, appearance: appearance)
    case .toggle:
      return appearance.minimumRowHeight
    }
  }

  private func makeHeaderView(header: FKActionSheetHeaderContent) -> UIView {
    switch header {
    case .text(let textHeader):
      return makeTextHeaderView(header: textHeader)
    case .custom(let customHeader):
      let view = FKActionSheetCustomHeaderView(frame: .zero)
      let context = FKActionSheetHeaderBuildContext(
        appearance: currentConfiguration.appearance,
        boundsWidth: max(1, bounds.width)
      )
      view.apply(header: customHeader, context: context)
      return view
    }
  }

  private func makeTextHeaderView(header: FKActionSheetHeader) -> UIView {
    let container = UIView()
    container.isAccessibilityElement = true
    container.accessibilityTraits = .header

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(stack)

    let appearance = currentConfiguration.appearance
    var accessibilityParts: [String] = []

    if let title = header.title, !title.isEmpty {
      let label = UILabel()
      label.font = appearance.resolvedHeaderTitleFont()
      label.textColor = appearance.headerTitleColor
      label.textAlignment = .center
      label.numberOfLines = 0
      label.text = title
      label.adjustsFontForContentSizeCategory = true
      stack.addArrangedSubview(label)
      accessibilityParts.append(title)
    }
    if let message = header.message, !message.isEmpty {
      let label = UILabel()
      label.font = appearance.resolvedHeaderMessageFont()
      label.textColor = appearance.headerMessageColor
      label.textAlignment = .center
      label.numberOfLines = 0
      label.text = message
      label.adjustsFontForContentSizeCategory = true
      stack.addArrangedSubview(label)
      accessibilityParts.append(message)
    }
    container.accessibilityLabel = accessibilityParts.joined(separator: ", ")

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
    ])
    return container
  }

  private func makeSectionTitleView(title: String) -> UIView {
    let label = UILabel()
    label.font = currentConfiguration.appearance.resolvedSectionTitleFont()
    label.textColor = currentConfiguration.appearance.sectionTitleColor
    label.text = title.uppercased()
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false
    let container = UIView()
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
    ])
    return container
  }
}

extension FKActionSheetCustomRowCell {
  static let defaultReuseIdentifier = "FKActionSheetCustomRow"
}
