import UIKit
import FKUIKit

/// Filter-strip preset with chevron accessories and ``FKTabBar/expandedItemID`` (visual only).
final class FKTabBarFilterStripExampleViewController: UIViewController, FKTabBarDelegate {
  private var items: [FKTabBarItem] = [
    FKTabBarItem(id: "all", title: .init(normal: .init(text: "All")), accessory: .init(kind: .chevron)),
    FKTabBarItem(id: "price", title: .init(normal: .init(text: "Price")), accessory: .init(kind: .chevron)),
    FKTabBarItem(id: "brand", title: .init(normal: .init(text: "Brand")), accessory: .init(kind: .chevron)),
    FKTabBarItem(id: "rating", title: .init(normal: .init(text: "Rating")), accessory: .init(kind: .chevron)),
  ]

  private lazy var tabView: FKTabBar = {
    let tab = FKTabBar(items: items, selectedIndex: 0, configuration: FKTabBarPresets.filterStrip())
    tab.selectionControlMode = .controlled
    tab.delegate = self
    tab.onSelectionRequest = { [weak self] item, index in
      self?.pendingSelectionIndex = index
      self?.appendLog("onSelectionRequest @\(index) (\(item.id)) — awaiting commit")
    }
    return tab
  }()

  private var pendingSelectionIndex: Int?
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter strip"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Accessory chevrons + expandedItemID"))
    stack.addArrangedSubview(
      FKTabBarExampleSupport.captionLabel(
        "Uses filterStrip preset, scroll edge fade, and controlled selection. expandedItemID rotates chevrons without changing selection."
      )
    )

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Commit pending selection") { [weak self] in
      self?.commitPendingSelection()
    })
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

    FKTabBarExampleSupport.attachPinnedTabBar(tabView, to: view, height: 48)
    appendLog("Tap a filter — controlled mode emits didRequestSelection before commit.")
  }

  private func commitPendingSelection() {
    guard let index = pendingSelectionIndex else {
      appendLog("No pending selection.")
      return
    }
    tabView.setSelectedIndex(index, animated: true, reason: .programmatic)
    pendingSelectionIndex = nil
    appendLog("Committed selection @\(index)")
  }

  private func toggleExpanded() {
    let selectedID = tabView.selectedItemID
    if tabView.expandedItemID == selectedID {
      tabView.expandedItemID = nil
      appendLog("expandedItemID = nil")
    } else {
      tabView.expandedItemID = selectedID
      appendLog("expandedItemID = \(selectedID ?? "nil")")
    }
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
      tabView.expandedItemID = nil
    }
  }
}
