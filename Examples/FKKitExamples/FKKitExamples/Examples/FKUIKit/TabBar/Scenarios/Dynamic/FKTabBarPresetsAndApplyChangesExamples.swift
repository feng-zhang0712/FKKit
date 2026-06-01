import UIKit
import FKUIKit

/// Compares shipped ``FKTabBarPresets`` factories side by side.
final class FKTabBarPresetsExampleViewController: UIViewController {
  private let presetControl = UISegmentedControl(items: ["Pager", "Segment", "Filter", "Bottom"])
  private var configuration = FKTabBarPresets.pagerHeader()
  private lazy var tabView = FKTabBar(
    items: FKTabBarExampleSupport.makeItems(5),
    selectedIndex: 0,
    configuration: configuration
  )
  private var tabHeightConstraint: NSLayoutConstraint?
  private let defaultBarHeight: CGFloat = 48

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presets"
    view.backgroundColor = .systemBackground

    tabHeightConstraint = FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: defaultBarHeight)

    let stack = FKTabBarExampleSupport.makeRootStack(
      in: view,
      scrollTopBelow: tabView.bottomAnchor,
      scrollTopSpacing: 16
    )
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("FKTabBarPresets factories"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "bottomDocked uses vertical icon+title layout — this demo expands bar height for that preset only."
      )
    )

    presetControl.selectedSegmentIndex = 0
    presetControl.addAction(UIAction { [weak self] _ in self?.applyPreset(animated: true) }, for: .valueChanged)
    stack.addArrangedSubview(presetControl)
  }

  private func applyPreset(animated: Bool) {
    let isBottomDocked = presetControl.selectedSegmentIndex == 3
    switch presetControl.selectedSegmentIndex {
    case 1:
      configuration = FKTabBarPresets.segmentedControl()
    case 2:
      configuration = FKTabBarPresets.filterStrip()
    case 3:
      configuration = FKTabBarPresets.bottomDocked(showsIndicator: false)
    default:
      configuration = FKTabBarPresets.pagerHeader()
    }
    tabView.applyConfiguration(configuration, animated: animated)
    updateTabBarHeight(isBottomDocked: isBottomDocked, animated: animated)
  }

  private func updateTabBarHeight(isBottomDocked: Bool, animated: Bool) {
    let targetHeight: CGFloat
    if isBottomDocked {
      tabView.invalidateIntrinsicContentSize()
      tabView.layoutIfNeeded()
      targetHeight = max(tabView.intrinsicContentSize.height, 83)
    } else {
      targetHeight = defaultBarHeight
    }
    tabHeightConstraint?.constant = targetHeight
    guard animated else {
      view.layoutIfNeeded()
      return
    }
    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
      self.view.layoutIfNeeded()
    }
  }
}

/// Demonstrates ``FKTabBar/applyChanges(_:updatePolicy:animated:completion:)`` and ID-based ``FKTabBar/reload(items:)``.
final class FKTabBarApplyChangesExampleViewController: UIViewController {
  private var items = FKTabBarExampleSupport.makeItems(5)
  private lazy var tabView = FKTabBar(items: items, selectedIndex: 1)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "applyChanges"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Batch mutations without full reloadData()"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "applyChanges performs insert/delete/move/update on the visible strip. reload(items:) uses ID diff when the visible ID sequence changes."
      )
    )

    let row1 = UIStackView()
    row1.axis = .horizontal
    row1.spacing = 8
    row1.distribution = .fillEqually
    row1.addArrangedSubview(FKTabBarExampleSupport.actionButton("Insert @2") { [weak self] in
      self?.insertSample()
    })
    row1.addArrangedSubview(FKTabBarExampleSupport.actionButton("Delete @1") { [weak self] in
      self?.deleteSecond()
    })
    stack.addArrangedSubview(row1)

    let row2 = UIStackView()
    row2.axis = .horizontal
    row2.spacing = 8
    row2.distribution = .fillEqually
    row2.addArrangedSubview(FKTabBarExampleSupport.actionButton("Move 0→2") { [weak self] in
      self?.moveFirstToThird()
    })
    row2.addArrangedSubview(FKTabBarExampleSupport.actionButton("Badge update") { [weak self] in
      self?.updateBadge()
    })
    stack.addArrangedSubview(row2)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("reload(items:) — refresh titles") { [weak self] in
      self?.reloadWithTitleRefresh()
    })

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 50)
  }

  private func insertSample() {
    let item = FKTabBarItem(
      id: "inserted-\(UUID().uuidString.prefix(4))",
      title: .init(normal: .init(text: "New")),
      badge: .init(state: .init(normal: .dot))
    )
    tabView.applyChanges([FKTabBarItemChange(kind: .insert(item, atVisibleIndex: 2))], animated: true)
    syncItemsFromTab()
  }

  private func deleteSecond() {
    guard tabView.visibleItems.count > 1 else { return }
    tabView.applyChanges([FKTabBarItemChange(kind: .delete(visibleIndex: 1))], animated: true)
    syncItemsFromTab()
  }

  private func moveFirstToThird() {
    guard tabView.visibleItems.count > 2 else { return }
    tabView.applyChanges(
      [FKTabBarItemChange(kind: .move(fromVisibleIndex: 0, toVisibleIndex: 2))],
      animated: true
    )
    syncItemsFromTab()
  }

  private func updateBadge() {
    guard let index = tabView.visibleItems.indices.first else { return }
    var item = tabView.visibleItems[index]
    item.badge.state.normal = .count((Int.random(in: 1...120)))
    tabView.applyChanges([FKTabBarItemChange(kind: .update(item, atVisibleIndex: index))], animated: false)
    syncItemsFromTab()
  }

  private func reloadWithTitleRefresh() {
    items = tabView.items.enumerated().map { offset, item in
      var next = item
      next.title.normal.text = "\(item.titleText ?? item.id) · \(offset)"
      return next
    }
    tabView.reload(items: items, updatePolicy: .preserveSelection)
  }

  private func syncItemsFromTab() {
    items = tabView.items
  }
}
