import UIKit
import FKUIKit

/// Filter-strip preset with chevron accessories and ``FKTabBar/expandedItemID`` (visual only).
final class FKTabBarFilterStripExampleViewController: UIViewController, FKTabBarDelegate {
  private var items: [FKTabBarItem] = [
    FKTabBarItem(id: "all", title: .init(normal: .init(text: "All")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "price", title: .init(normal: .init(text: "Price")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "brand", title: .init(normal: .init(text: "Brand")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "rating", title: .init(normal: .init(text: "Rating")), accessory: .init(chevron: .init())),
  ]

  private var chevronAnimatesRotation = true
  private var usesCompactChevron = false
  private var usesSecondaryTint = false
  private var chevronWeight: FKTabBarChevronSymbolWeight = .semibold
  private var usesPendingSelection = false

  private let pendingSelectionSwitch = UISwitch()
  private let animateSwitch = UISwitch()
  private let compactChevronSwitch = UISwitch()
  private let secondaryTintSwitch = UISwitch()
  private let weightControl = UISegmentedControl(items: ["Regular", "Semi", "Bold"])
  private lazy var commitButton = FKTabBarExampleSupport.actionButton("Commit pending selection") { [weak self] in
    self?.commitPendingSelection()
  }

  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(items: items, selectedIndex: 0, configuration: FKTabBarPresets.filterStrip())
    tab.delegate = self
    tab.onSelectionRequest = { [weak self] item, index in
      guard let self, self.usesPendingSelection else { return }
      self.pendingSelectionIndex = index
      self.updateCommitButtonState()
      self.appendLog("onSelectionRequest @\(index) (\(item.id)) — awaiting commit")
    }
    return tab
  }()

  private var pendingSelectionIndex: Int?

  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter strip"
    view.backgroundColor = .systemBackground

    syncAccessoryConfiguration(reload: false)
    applyPendingSelectionMode()

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Accessory chevrons + expandedItemID"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Built-in chevrons render chevron.down only. This page rotates the trailing image view in host code after expandedItemID changes (see visibleItemButton + UIView.animate)."
      )
    )

    stack.addArrangedSubview(switchRow(title: "Pending selection (controlled mode)", switchControl: pendingSelectionSwitch))
    stack.addArrangedSubview(commitButton)
    stack.addArrangedSubview(switchRow(title: "Animate chevron rotation (180°)", switchControl: animateSwitch))
    stack.addArrangedSubview(switchRow(title: "Compact chevron (10pt)", switchControl: compactChevronSwitch))
    stack.addArrangedSubview(switchRow(title: "Secondary tint color", switchControl: secondaryTintSwitch))
    stack.addArrangedSubview(labeledControl("Chevron weight", weightControl))

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle expand selected") { [weak self] in
      self?.toggleExpanded()
    })

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    stack.addArrangedSubview(logView)

    wireControls()
    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 48)
    appendLog("Tap a filter to select, then use Toggle expand selected to preview chevron rotation.")
  }

  private func wireControls() {
    pendingSelectionSwitch.isOn = usesPendingSelection
    animateSwitch.isOn = chevronAnimatesRotation
    compactChevronSwitch.isOn = usesCompactChevron
    secondaryTintSwitch.isOn = usesSecondaryTint
    weightControl.selectedSegmentIndex = 1
    updateCommitButtonState()

    pendingSelectionSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesPendingSelection = control.isOn
      self.applyPendingSelectionMode()
      self.appendLog("pending selection = \(control.isOn)")
    }, for: .valueChanged)

    animateSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.chevronAnimatesRotation = control.isOn
      self.appendLog("animated rotation = \(control.isOn)")
    }, for: .valueChanged)

    compactChevronSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesCompactChevron = control.isOn
      self.syncAccessoryConfiguration()
      self.appendLog("pointSize = \(control.isOn ? 10 : 14)")
    }, for: .valueChanged)

    secondaryTintSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesSecondaryTint = control.isOn
      self.syncAccessoryConfiguration()
      self.appendLog("tintColor = \(control.isOn ? "secondaryLabel" : "title")")
    }, for: .valueChanged)

    weightControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0: self.chevronWeight = .regular
      case 2: self.chevronWeight = .bold
      default: self.chevronWeight = .semibold
      }
      self.syncAccessoryConfiguration()
      self.appendLog("weight = \(self.chevronWeight)")
    }, for: .valueChanged)
  }

  private func applyPendingSelectionMode() {
    tabView.selectionControlMode = usesPendingSelection ? .controlled : .uncontrolled
    if !usesPendingSelection {
      pendingSelectionIndex = nil
    }
    updateCommitButtonState()
  }

  private func updateCommitButtonState() {
    commitButton.isHidden = !usesPendingSelection
    commitButton.isEnabled = usesPendingSelection && pendingSelectionIndex != nil
    commitButton.alpha = commitButton.isEnabled ? 1 : 0.5
  }

  private func switchRow(title: String, switchControl: UISwitch) -> UIStackView {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.text = title
    label.numberOfLines = 0
    let row = UIStackView(arrangedSubviews: [label, switchControl])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    label.setContentHuggingPriority(.defaultLow, for: .horizontal)
    switchControl.setContentHuggingPriority(.required, for: .horizontal)
    return row
  }

  private func labeledControl(_ title: String, _ control: UIControl) -> UIStackView {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.text = title
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .vertical
    row.spacing = 6
    return row
  }

  private func syncAccessoryConfiguration(reload: Bool = true) {
    let chevron = FKTabBarChevronAccessoryConfiguration(
      pointSize: usesCompactChevron ? 10 : 14,
      weight: chevronWeight,
      tintColor: usesSecondaryTint ? .secondaryLabel : nil
    )
    let accessory = FKTabBarAccessoryConfiguration(chevron: chevron)
    items = items.map { item in
      var copy = item
      copy.accessory = accessory
      return copy
    }
    guard reload else { return }
    tabView.reload(items: items, updatePolicy: .preserveSelection)
    restoreExpandedChevronVisuals()
  }

  private func commitPendingSelection() {
    guard usesPendingSelection else { return }
    guard let index = pendingSelectionIndex else {
      appendLog("No pending selection.")
      return
    }
    tabView.setSelectedIndex(index, animated: true, reason: .programmatic)
    pendingSelectionIndex = nil
    updateCommitButtonState()
    appendLog("Committed selection @\(index)")
  }

  private func toggleExpanded() {
    let index = tabView.selectedIndex
    guard let selectedID = tabView.selectedItemID else { return }
    let willExpand = tabView.expandedItemID != selectedID

    tabView.expandedItemID = willExpand ? selectedID : nil
    appendLog("expandedItemID = \(willExpand ? selectedID : "nil")")
    applyChevronRotation(at: index, expanded: willExpand)
  }

  /// Rotates the built-in chevron after ``FKTabBar`` finishes its synchronous cell refresh.
  ///
  /// ``expandedItemID`` triggers a full item re-apply that recreates the trailing ``UIImageView``.
  /// Host animation must run on the post-refresh view, not inside ``FKTabBarCustomization``.
  private func applyChevronRotation(at index: Int, expanded: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard let chevronView = self.tabView.visibleItemButton(at: index)?.trailingImageView else { return }

      let targetTransform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
      if self.chevronAnimatesRotation {
        UIView.animate(
          withDuration: 0.28,
          delay: 0,
          options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
          chevronView.transform = targetTransform
        }
      } else {
        chevronView.transform = targetTransform
      }
    }
  }

  private func restoreExpandedChevronVisuals() {
    guard let expandedID = tabView.expandedItemID,
          let index = tabView.visibleItems.firstIndex(where: { $0.id == expandedID }) else { return }
    applyChevronRotation(at: index, expanded: true)
  }

  private func collapseExpandedChevronIfNeeded(previousExpandedID: String?) {
    guard let previousExpandedID,
          let index = tabView.visibleItems.firstIndex(where: { $0.id == previousExpandedID }) else { return }
    applyChevronRotation(at: index, expanded: false)
  }

  private func appendLog(_ line: String) {
    logView.text = (logView.text ?? "") + line + "\n"
  }

  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int) {
    appendLog("delegate didRequestSelection @\(index)")
  }

  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    appendLog("delegate didSelect @\(index) reason=\(reason)")
    if tabView.expandedItemID != nil, tabView.expandedItemID != item.id {
      let previousExpandedID = tabView.expandedItemID
      tabView.expandedItemID = nil
      collapseExpandedChevronIfNeeded(previousExpandedID: previousExpandedID)
    }
  }
}
