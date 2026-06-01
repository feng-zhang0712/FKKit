import UIKit
import FKUIKit

/// Filter-strip preset demonstrating host-owned accessory animations via ``FKTabBar/visibleItemChevronView(at:)`` and ``FKTabBar/visibleItemAccessoryView(at:)``.
final class FKTabBarFilterStripExampleViewController: UIViewController, FKTabBarDelegate {
  private enum AccessoryAnimationStyle: String {
    case chevronFlipUp
    case chevronRotateClockwise90
    case chevronRotateCounter90
    case chevronSpringFlipUp
    case customHeartbeat
    case customBounce
  }

  private var items: [FKTabBarItem] = [
    FKTabBarItem(id: "all", title: .init(normal: .init(text: "All")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "price", title: .init(normal: .init(text: "Price")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "brand", title: .init(normal: .init(text: "Brand")), accessory: .init(chevron: .init())),
    FKTabBarItem(id: "rating", title: .init(normal: .init(text: "Rating")), accessory: .init(chevron: .init())),
    FKTabBarItem(
      id: "favorites",
      title: .init(normal: .init(text: "Favorites")),
      accessory: .init(kind: .custom(id: "heart"), spacing: 4)
    ),
    FKTabBarItem(
      id: "saved",
      title: .init(normal: .init(text: "Saved")),
      accessory: .init(kind: .custom(id: "sparkle"), spacing: 4)
    ),
  ]

  private let animationStyleByItemID: [String: AccessoryAnimationStyle] = [
    "all": .chevronFlipUp,
    "price": .chevronRotateClockwise90,
    "brand": .chevronRotateCounter90,
    "rating": .chevronSpringFlipUp,
    "favorites": .customHeartbeat,
    "saved": .customBounce,
  ]

  private var accessoryAnimates = true
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

  private let accessoryCustomization = FilterStripExampleAccessoryCustomization()

  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(items: items, selectedIndex: 0, configuration: FKTabBarPresets.filterStrip())
    tab.customization = accessoryCustomization
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

    syncChevronAccessoryConfiguration(reload: false)
    applyPendingSelectionMode()

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Host-owned accessory animations"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        """
        Each tab uses a different host animation after didSelect. Chevrons: flip 180°, ±90°, spring flip. \
        Custom: heart heartbeat, sparkles bounce. FKTabBar exposes views only — no built-in accessory animation.
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
        title: "Apply selection accessory effects (animated when on, skipped when off)",
        switchControl: animateSwitch
      )
    )
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
      self.accessoryAnimates = control.isOn
      if control.isOn {
        self.syncAccessoryAnimationsForSelection(selectedIndex: self.tabView.selectedIndex)
      } else {
        self.resetAllVisibleAccessoryEffects()
      }
      self.appendLog("selection accessory effects = \(control.isOn)")
    }, for: .valueChanged)

    compactChevronSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesCompactChevron = control.isOn
      self.syncChevronAccessoryConfiguration()
      self.appendLog("pointSize = \(control.isOn ? 10 : 14)")
    }, for: .valueChanged)

    secondaryTintSwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.usesSecondaryTint = control.isOn
      self.syncChevronAccessoryConfiguration()
      self.appendLog("tintColor = \(control.isOn ? "secondaryLabel" : "title")")
    }, for: .valueChanged)

    weightControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0: self.chevronWeight = .regular
      case 2: self.chevronWeight = .bold
      default: self.chevronWeight = .semibold
      }
      self.syncChevronAccessoryConfiguration()
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

  private func syncChevronAccessoryConfiguration(reload: Bool = true) {
    let chevron = FKTabBarChevronAccessoryConfiguration(
      pointSize: usesCompactChevron ? 10 : 14,
      weight: chevronWeight,
      tintColor: usesSecondaryTint ? .secondaryLabel : nil
    )
    items = items.map { item in
      guard item.accessory.chevronConfiguration != nil else { return item }
      var copy = item
      copy.accessory = FKTabBarAccessoryConfiguration(chevron: chevron)
      return copy
    }
    guard reload else { return }
    tabView.reload(items: items, updatePolicy: .preserveSelection)
    syncAccessoryAnimationsForSelection(selectedIndex: tabView.selectedIndex)
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
          let style = animationStyle(for: tabView.visibleItems[index].id) else { return }

    switch style {
    case .chevronFlipUp, .chevronRotateClockwise90, .chevronRotateCounter90, .chevronSpringFlipUp:
      guard let chevronView = tabView.visibleItemChevronView(at: index) else { return }
      chevronView.layer.removeAllAnimations()
      chevronView.transform = .identity
    case .customHeartbeat, .customBounce:
      guard let accessoryView = tabView.visibleItemAccessoryView(at: index) else { return }
      accessoryView.layer.removeAllAnimations()
      accessoryView.transform = .identity
    }
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
      applyChevronTransform(at: index, angle: .pi, style: style)
    case .chevronRotateClockwise90:
      applyChevronTransform(at: index, angle: -.pi / 2, style: style)
    case .chevronRotateCounter90:
      applyChevronTransform(at: index, angle: .pi / 2, style: style)
    case .chevronSpringFlipUp:
      applyChevronTransform(at: index, angle: .pi, style: style, usesSpring: true)
    case .customHeartbeat:
      applyHeartbeat(to: tabView.visibleItemAccessoryView(at: index), style: style)
    case .customBounce:
      applyBounce(to: tabView.visibleItemAccessoryView(at: index), style: style)
    }
  }

  private func applyChevronTransform(
    at index: Int,
    angle: CGFloat,
    style: AccessoryAnimationStyle,
    usesSpring: Bool = false
  ) {
    guard let chevronView = tabView.visibleItemChevronView(at: index) else { return }
    let targetTransform = CGAffineTransform(rotationAngle: angle)

    if usesSpring {
      UIView.animate(
        withDuration: 0.55,
        delay: 0,
        usingSpringWithDamping: 0.58,
        initialSpringVelocity: 0.9,
        options: [.beginFromCurrentState, .allowUserInteraction]
      ) {
        chevronView.transform = targetTransform
      }
    } else {
      UIView.animate(
        withDuration: 0.28,
        delay: 0,
        options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
      ) {
        chevronView.transform = targetTransform
      }
    }
    appendLog("accessory \(style.rawValue) @\(index)")
  }

  private func applyHeartbeat(to view: UIView?, style: AccessoryAnimationStyle) {
    guard let view else { return }
    view.layer.removeAllAnimations()
    view.transform = .identity

    let steps: [(CGFloat, TimeInterval)] = [(1.35, 0.12), (0.92, 0.12), (1.0, 0.1)]
    runTransformSteps(on: view, steps: steps, style: style)
  }

  private func applyBounce(to view: UIView?, style: AccessoryAnimationStyle) {
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

  /// Runs after ``FKTabBar`` finishes its selection refresh so accessory views exist and transforms can be applied safely.
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

// MARK: - Custom accessory rendering

@MainActor
private final class FilterStripExampleAccessoryCustomization: FKTabBarDefaultCustomization {
  override func customAccessoryView(for item: FKTabBarItem, isSelected: Bool, isExpanded: Bool) -> UIView? {
    guard case .custom(let id) = item.accessory.kind else { return nil }

    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)

    switch id {
    case "heart":
      imageView.image = UIImage(systemName: "heart.fill")
      imageView.tintColor = isSelected ? .systemPink : .secondaryLabel
    case "sparkle":
      imageView.image = UIImage(systemName: "sparkles")
      imageView.tintColor = isSelected ? .systemYellow : .secondaryLabel
    default:
      return nil
    }

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 16),
      imageView.heightAnchor.constraint(equalToConstant: 16),
    ])
    return imageView
  }
}
