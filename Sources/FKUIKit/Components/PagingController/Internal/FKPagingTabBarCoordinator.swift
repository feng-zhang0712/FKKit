import UIKit

@MainActor
protocol FKPagingTabBarCoordinatorDelegate: AnyObject {
  func pagingCoordinatorDidRequestSwitch(to index: Int, animated: Bool)
  func pagingCoordinatorDidRequestSelection(at index: Int)
  func pagingCoordinatorDidReselect(at index: Int)
}

@MainActor
final class FKPagingTabBarCoordinator: NSObject {
  weak var delegate: FKPagingTabBarCoordinatorDelegate?
  private weak var tabBar: FKTabBar?
  private weak var forwardedDelegate: FKTabBarDelegate?

  func bind(tabBar: FKTabBar, forwardedDelegate: FKTabBarDelegate?) {
    self.tabBar = tabBar
    self.forwardedDelegate = forwardedDelegate
    tabBar.delegate = self
  }

  func syncProgress(from: Int, to: Int, progress: CGFloat) {
    tabBar?.setSelectionProgress(from: from, to: to, progress: progress)
  }

  func syncSettled(index: Int, animated: Bool) {
    tabBar?.setSelectedIndex(index, animated: animated, notify: false, reason: .interaction)
  }

  func applyPageSwitchGate(_ gate: FKPagingPageSwitchGate, scope: FKPagingPageSwitchGateScope) {
    let tabControlled = gate == .controlled && (scope == .tabSelectionOnly || scope == .all)
    tabBar?.selectionControlMode = tabControlled ? .controlled : .uncontrolled
  }

  private var isControlledGate: Bool {
    tabBar?.selectionControlMode == .controlled
  }
}

extension FKPagingTabBarCoordinator: FKTabBarDelegate {
  func tabBar(_ tabBar: FKTabBar, shouldSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) -> Bool {
    forwardedDelegate?.tabBar(tabBar, shouldSelect: item, at: index, reason: reason) ?? true
  }

  func tabBar(_ tabBar: FKTabBar, willSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    forwardedDelegate?.tabBar(tabBar, willSelect: item, at: index, reason: reason)
  }

  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    forwardedDelegate?.tabBar(tabBar, didSelect: item, at: index, reason: reason)
    guard reason == .userTap, !isControlledGate else { return }
    delegate?.pagingCoordinatorDidRequestSwitch(to: index, animated: true)
  }

  func tabBar(_ tabBar: FKTabBar, didReselect item: FKTabBarItem, at index: Int) {
    forwardedDelegate?.tabBar(tabBar, didReselect: item, at: index)
    delegate?.pagingCoordinatorDidReselect(at: index)
  }

  func tabBar(_ tabBar: FKTabBar, didLongPress item: FKTabBarItem, at index: Int) {
    forwardedDelegate?.tabBar(tabBar, didLongPress: item, at: index)
  }

  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int) {
    forwardedDelegate?.tabBar(tabBar, didRequestSelection: item, at: index)
    guard isControlledGate else { return }
    delegate?.pagingCoordinatorDidRequestSelection(at: index)
  }

  func tabBar(_ tabBar: FKTabBar, didReloadItems items: [FKTabBarItem], visibleItems: [FKTabBarItem], selectedIndex: Int) {
    forwardedDelegate?.tabBar(tabBar, didReloadItems: items, visibleItems: visibleItems, selectedIndex: selectedIndex)
  }
}
