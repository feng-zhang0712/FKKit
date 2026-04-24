import UIKit

@MainActor
protocol FKPagingTabBarCoordinatorDelegate: AnyObject {
  func pagingCoordinatorDidRequestSwitch(to index: Int, animated: Bool)
}

@MainActor
final class FKPagingTabBarCoordinator: NSObject {
  weak var delegate: FKPagingTabBarCoordinatorDelegate?
  private weak var tabBar: FKTabBar?
  private var suppressTabSelectionCallback = false

  func bind(tabBar: FKTabBar) {
    self.tabBar = tabBar
    tabBar.delegate = self
  }

  func syncProgress(from: Int, to: Int, progress: CGFloat) {
    tabBar?.setSelectionProgress(from: from, to: to, progress: progress)
  }

  func syncSettled(index: Int, animated: Bool) {
    guard let tabBar else { return }
    suppressTabSelectionCallback = true
    tabBar.setSelectedIndex(index, animated: animated, reason: .interaction)
    suppressTabSelectionCallback = false
  }
}

extension FKPagingTabBarCoordinator: FKTabBarDelegate {
  func tabBar(_ tabBar: FKTabBar, shouldSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) -> Bool {
    true
  }

  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    guard !suppressTabSelectionCallback else { return }
    guard reason == .userTap else { return }
    delegate?.pagingCoordinatorDidRequestSwitch(to: index, animated: true)
  }

  func tabBar(_ tabBar: FKTabBar, didReselect item: FKTabBarItem, at index: Int) {}
}
