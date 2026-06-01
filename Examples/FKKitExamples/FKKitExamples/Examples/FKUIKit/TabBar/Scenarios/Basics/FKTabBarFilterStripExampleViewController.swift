import UIKit
import FKUIKit

/// Filter-strip preset demonstrating host-owned accessory animations via ``FKTabBar/visibleItemAccessoryView(at:)``.
final class FKTabBarFilterStripExampleViewController: UIViewController, FKTabBarDelegate {
  private enum AccessoryAnimationStyle: String {
    case chevronFlipUp
    case chevronRotateClockwise90
    case chevronRotateCounter90
    case chevronSpringFlipUp
    case iconHeartbeat
    case iconBounce
  }

  private var items: [FKTabBarItem] = [
    FKTabBarItem(id: "all", title: .init(normal: .init(text: "All")), accessory: chevronDownAccessory()),
    FKTabBarItem(id: "price", title: .init(normal: .init(text: "Price")), accessory: chevronDownAccessory()),
    FKTabBarItem(id: "brand", title: .init(normal: .init(text: "Brand")), accessory: chevronDownAccessory()),
    FKTabBarItem(id: "rating", title: .init(normal: .init(text: "Rating")), accessory: chevronDownAccessory()),
    FKTabBarItem(id: "favorites", title: .init(normal: .init(text: "Favorites")), accessory: heartAccessory()),
    FKTabBarItem(id: "saved", title: .init(normal: .init(text: "Saved")), accessory: sparklesAccessory()),
  ]

  private let animationStyleByItemID: [String: AccessoryAnimationStyle] = [
    "all": .chevronFlipUp,
    "price": .chevronRotateClockwise90,
    "brand": .chevronRotateCounter90,
    "rating": .chevronSpringFlipUp,
    "favorites": .iconHeartbeat,
    "saved": .iconBounce,
  ]

  private var accessoryAnimates = true
  private var usesCompactIcon = false
  private var usesSecondaryTint = false
  private var iconWeight: FKTabBarAccessorySymbolWeight = .semibold
  private var usesPendingSelection = false

  private let pendingSelectionSwitch = UISwitch()
  private let animateSwitch = UISwitch()
  private let compactIconSwitch = UISwitch()
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
  private var lastAnimatedSelectionIndex: Int?

  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter strip"
    view.backgroundColor = .systemBackground

    syncIconAccessoryConfiguration(reload: false)
    applyPendingSelectionMode()

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Host-owned accessory animations"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        """
        Each tab configures a trailing icon on the item model. Host code animates \
        ``FKTabBar/visibleItemAccessoryView(at:)`` after didSelect (rotation, heartbeat, bounce).
        """
      )
    )
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "All/Price/Brand/Rating → chevron.down · Favorites → heart.fill · Saved → sparkles"
      )
    )

    stack.addArrangedSubview(switchRow(title: "Pending selection (controlled mode)", switchControl: pendingSelectionSwitch))
    stack.addArrangedSubview(commitButton)
    stack.addArrangedSubview(
      switchRow(
        title: "Animate on selection",
        switchControl: animateSwitch
      )
    )
    stack.addArrangedSubview(switchRow(title: "Compact icon (10pt)", switchControl: compactIconSwitch))
    stack.addArrangedSubview(switchRow(title: "Secondary tint color", switchControl: secondaryTintSwitch))
    stack.addArrangedSubview(labeledControl("Icon weight", weightControl))

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Toggle expand selected") { [weak self] in
      self?.toggleExpanded()
    })

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    logView.heightAnchor.constraint(equalToConstant: 160).isActive = true
    stack.addArrangedSubview(logView)

    wireControls()
    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 48)
    appendLog("Tap tabs to preview per-item animations. Toggle expand selected demos expandedItemID only.")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard accessoryAnimates else { return }
    syncAccessoryAnimationsForSelection(selectedIndex: tabView.selectedIndex)
  }

  private func wireControls() {
    pendingSelectionSwitch.isOn = usesPendingSelection
    animateSwitch.isOn = accessoryAnimates
    compactIconSwitch.isOn = usesCompactIcon
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
      self.accessoryAnimates = control.isOn
      if control.isOn {
        self.syncAccessoryAnimationsForSelection(selectedIndex: self.tabView.selectedIndex)
      } else {
        self.resetAllVisibleAccessoryEffects()
      }
      self.appendLog("selection accessory effects = \(control.isOn)")
    }, for: .valueChanged)

    compactIconSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesCompactIcon = control.isOn
      self.syncIconAccessoryConfiguration()
      self.appendLog("pointSize = \(control.isOn ? 10 : 14)")
    }, for: .valueChanged)

    secondaryTintSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesSecondaryTint = control.isOn
      self.syncIconAccessoryConfiguration()
      self.appendLog("tintColor = \(control.isOn ? "secondaryLabel" : "title")")
    }, for: .valueChanged)

    weightControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0: self.iconWeight = .regular
      case 2: self.iconWeight = .bold
      default: self.iconWeight = .semibold
      }
      self.syncIconAccessoryConfiguration()
      self.appendLog("weight = \(self.iconWeight)")
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
    label.setContentHuggingPriority(.defaultLow, for: .horizontal)
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    switchControl.setContentHuggingPriority(.required, for: .horizontal)
    switchControl.setContentCompressionResistancePriority(.required, for: .horizontal)
    let row = UIStackView(arrangedSubviews: [label, switchControl])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
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

  private func sharedIconStyle(tintColor: UIColor? = nil) -> FKTabBarAccessoryIconStyle {
    FKTabBarAccessoryIconStyle(
      pointSize: usesCompactIcon ? 10 : 14,
      weight: iconWeight,
      tintColor: tintColor ?? (usesSecondaryTint ? .secondaryLabel : nil)
    )
  }

  private func syncIconAccessoryConfiguration(reload: Bool = true) {
    items = items.map { item in
      var copy = item
      switch item.id {
      case "all", "price", "brand", "rating":
        copy.accessory = chevronDownAccessory(style: sharedIconStyle())
      case "favorites":
        copy.accessory = heartAccessory(style: sharedIconStyle())
      case "saved":
        copy.accessory = sparklesAccessory(style: sharedIconStyle())
      default:
        break
      }
      return copy
    }
    guard reload else { return }
    tabView.reload(items: items, updatePolicy: .preserveSelection)
    if accessoryAnimates {
      syncAccessoryAnimationsForSelection(selectedIndex: tabView.selectedIndex)
    }
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
    syncAccessoryAnimationsForSelection(selectedIndex: index)
  }

  private func toggleExpanded() {
    guard let selectedID = tabView.selectedItemID else { return }
    let willExpand = tabView.expandedItemID != selectedID

    tabView.expandedItemID = willExpand ? selectedID : nil
    appendLog("expandedItemID = \(willExpand ? selectedID : "nil") (visual state only; animations follow selection)")
  }

  private func animationStyle(for itemID: String) -> AccessoryAnimationStyle? {
    animationStyleByItemID[itemID]
  }

  private func resetAccessoryEffect(at index: Int) {
    guard tabView.visibleItems.indices.contains(index),
          animationStyle(for: tabView.visibleItems[index].id) != nil else { return }
    guard let iconView = tabView.visibleItemAccessoryView(at: index) else { return }
    iconView.layer.removeAllAnimations()
    iconView.transform = .identity
  }

  private func resetAllVisibleAccessoryEffects() {
    lastAnimatedSelectionIndex = nil
    for index in tabView.visibleItems.indices {
      resetAccessoryEffect(at: index)
    }
  }

  private func applyAccessoryAnimation(at index: Int, selected: Bool) {
    guard accessoryAnimates else { return }
    guard tabView.visibleItems.indices.contains(index) else { return }
    let itemID = tabView.visibleItems[index].id
    guard let style = animationStyle(for: itemID) else { return }

    guard selected else {
      resetAccessoryEffect(at: index)
      return
    }

    switch style {
    case .chevronFlipUp:
      applyIconTransform(at: index, angle: .pi, style: style)
    case .chevronRotateClockwise90:
      applyIconTransform(at: index, angle: -.pi / 2, style: style)
    case .chevronRotateCounter90:
      applyIconTransform(at: index, angle: .pi / 2, style: style)
    case .chevronSpringFlipUp:
      applyIconTransform(at: index, angle: .pi, style: style, usesSpring: true)
    case .iconHeartbeat:
      applyHeartbeat(to: tabView.visibleItemAccessoryView(at: index), style: style)
    case .iconBounce:
      applyBounce(to: tabView.visibleItemAccessoryView(at: index), style: style)
    }
  }

  private func applyIconTransform(
    at index: Int,
    angle: CGFloat,
    style: AccessoryAnimationStyle,
    usesSpring: Bool = false
  ) {
    guard let iconView = tabView.visibleItemAccessoryView(at: index) else { return }
    let targetTransform = CGAffineTransform(rotationAngle: angle)

    if usesSpring {
      UIView.animate(
        withDuration: 0.55,
        delay: 0,
        usingSpringWithDamping: 0.58,
        initialSpringVelocity: 0.9,
        options: [.beginFromCurrentState, .allowUserInteraction]
      ) {
        iconView.transform = targetTransform
      }
    } else {
      UIView.animate(
        withDuration: 0.28,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
      ) {
        iconView.transform = targetTransform
      }
    }
    appendLog("accessory \(style.rawValue) @\(index)")
  }

  private func applyHeartbeat(to view: UIImageView?, style: AccessoryAnimationStyle) {
    guard let view else { return }
    view.layer.removeAllAnimations()
    view.transform = .identity

    let steps: [(CGFloat, TimeInterval)] = [(1.35, 0.12), (0.92, 0.12), (1.0, 0.1)]
    runTransformSteps(on: view, steps: steps, style: style)
  }

  private func applyBounce(to view: UIImageView?, style: AccessoryAnimationStyle) {
    guard let view else { return }
    view.layer.removeAllAnimations()
    view.transform = .identity

    let steps: [(CGFloat, TimeInterval)] = [(1.28, 0.14), (0.88, 0.1), (1.06, 0.08), (1.0, 0.08)]
    runTransformSteps(on: view, steps: steps, style: style)
  }

  private func runTransformSteps(on view: UIView, steps: [(scale: CGFloat, duration: TimeInterval)], style: AccessoryAnimationStyle) {
    func runStep(_ index: Int) {
      guard index < steps.count else {
        appendLog("accessory \(style.rawValue)")
        return
      }
      let step = steps[index]
      UIView.animate(withDuration: step.duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
        view.transform = step.scale == 1 ? .identity : CGAffineTransform(scaleX: step.scale, y: step.scale)
      } completion: { _ in
        runStep(index + 1)
      }
    }
    runStep(0)
  }

  private func syncAccessoryAnimationsForSelection(selectedIndex: Int) {
    guard accessoryAnimates else { return }

    if let previous = lastAnimatedSelectionIndex, previous != selectedIndex {
      applyAccessoryAnimation(at: previous, selected: false)
    }
    applyAccessoryAnimation(at: selectedIndex, selected: true)
    lastAnimatedSelectionIndex = selectedIndex
  }

  private func appendLog(_ line: String) {
    logView.text = (logView.text ?? "") + line + "\n"
  }

  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int) {
    appendLog("delegate didRequestSelection @\(index)")
  }

  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    appendLog("delegate didSelect @\(index) (\(item.id)) reason=\(reason)")
    if accessoryAnimates {
      syncAccessoryAnimationsForSelection(selectedIndex: index)
    }
    if tabView.expandedItemID != nil, tabView.expandedItemID != item.id {
      tabView.expandedItemID = nil
      appendLog("expandedItemID cleared (selection changed)")
    }
  }
}

// MARK: - Accessory factories

private func chevronDownAccessory(
  style: FKTabBarAccessoryIconStyle = FKTabBarAccessoryIconStyle()
) -> FKTabBarAccessoryConfiguration {
  .init(icon: .systemSymbol("chevron.down", style: style))
}

private func heartAccessory(
  style: FKTabBarAccessoryIconStyle = FKTabBarAccessoryIconStyle()
) -> FKTabBarAccessoryConfiguration {
  .init(
    icon: .init(
      normal: .init(
        source: .systemSymbol(name: "heart.fill"),
        style: FKTabBarAccessoryIconStyle(
          pointSize: style.pointSize,
          weight: style.weight,
          tintColor: .secondaryLabel,
          fixedSize: style.fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      ),
      selected: .init(
        source: .systemSymbol(name: "heart.fill"),
        style: FKTabBarAccessoryIconStyle(
          pointSize: style.pointSize,
          weight: style.weight,
          tintColor: .systemPink,
          fixedSize: style.fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      )
    )
  )
}

private func sparklesAccessory(
  style: FKTabBarAccessoryIconStyle = FKTabBarAccessoryIconStyle()
) -> FKTabBarAccessoryConfiguration {
  .init(
    icon: .init(
      normal: .init(
        source: .systemSymbol(name: "sparkles"),
        style: FKTabBarAccessoryIconStyle(
          pointSize: style.pointSize,
          weight: style.weight,
          tintColor: .secondaryLabel,
          fixedSize: style.fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      ),
      selected: .init(
        source: .systemSymbol(name: "sparkles"),
        style: FKTabBarAccessoryIconStyle(
          pointSize: style.pointSize,
          weight: style.weight,
          tintColor: .systemYellow,
          fixedSize: style.fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      )
    )
  )
}
