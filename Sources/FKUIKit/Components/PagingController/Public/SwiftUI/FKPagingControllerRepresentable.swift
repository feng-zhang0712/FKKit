#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI integration for ``FKPagingController``.
///
/// Supports both eager view-controller arrays and lazy construction. Host updates call
/// ``FKPagingController/setContent(tabs:viewControllers:selectedIndex:)`` or the lazy variant when
/// diffing detects meaningful changes.
@MainActor
public struct FKPagingControllerRepresentable: UIViewControllerRepresentable {
  public typealias UIViewControllerType = FKPagingController

  private let tabs: [FKTabBarItem]
  private let pageSource: PageSource
  private let tabConfiguration: FKTabBarConfiguration
  private let configuration: FKPagingConfiguration
  @Binding private var selectedIndex: Int

  fileprivate enum PageSource {
    case eager([UIViewController])
    case lazy(pageCount: Int, provider: (Int) -> UIViewController)
  }

  /// Eager page construction.
  public init(
    tabs: [FKTabBarItem],
    pages: [UIViewController],
    selectedIndex: Binding<Int>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    self.tabs = tabs
    self.pageSource = .eager(pages)
    self._selectedIndex = selectedIndex
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
  }

  /// Lazy page construction.
  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Binding<Int>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    self.tabs = tabs
    self.pageSource = .lazy(pageCount: pageCount, provider: pageProvider)
    self._selectedIndex = selectedIndex
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
  }

  public func makeUIViewController(context: Context) -> FKPagingController {
    let controller: FKPagingController
    switch pageSource {
    case .eager(let pages):
      controller = FKPagingController(
        tabs: tabs,
        viewControllers: pages,
        selectedIndex: selectedIndex,
        tabConfiguration: tabConfiguration,
        configuration: configuration
      )
    case .lazy(let count, let provider):
      controller = FKPagingController(
        tabs: tabs,
        pageCount: count,
        pageProvider: provider,
        selectedIndex: selectedIndex,
        tabConfiguration: tabConfiguration,
        configuration: configuration
      )
    }
    controller.delegate = context.coordinator
    context.coordinator.cache(from: tabs, pageSource: pageSource)
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKPagingController, context: Context) {
    if context.coordinator.lastConfiguration != configuration {
      uiViewController.configuration = configuration
      context.coordinator.lastConfiguration = configuration
    }
    if context.coordinator.lastTabConfiguration != tabConfiguration {
      uiViewController.tabBar.applyConfiguration(tabConfiguration)
      context.coordinator.lastTabConfiguration = tabConfiguration
    }

    let coordinator = context.coordinator
    if coordinator.shouldReloadStructure(tabs: tabs, pageSource: pageSource) {
      switch pageSource {
      case .eager(let pages):
        uiViewController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: selectedIndex)
      case .lazy(let count, let provider):
        uiViewController.setContent(tabs: tabs, pageCount: count, pageProvider: provider, selectedIndex: selectedIndex)
      }
      coordinator.cache(from: tabs, pageSource: pageSource)
    } else if tabs != coordinator.cachedTabs {
      uiViewController.tabBar.reload(items: tabs, updatePolicy: .preserveSelection)
      coordinator.cachedTabs = tabs
    }
    if uiViewController.selectedIndex != selectedIndex {
      uiViewController.setSelectedIndex(selectedIndex, animated: context.transaction.animation != nil)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex)
  }

  @MainActor
  public final class Coordinator: NSObject, FKPagingControllerDelegate {
    private var selectedIndex: Binding<Int>
    fileprivate var cachedTabs: [FKTabBarItem] = []
    private var cachedVisibleTabIDs: [String] = []
    private var cachedPageObjectIDs: [ObjectIdentifier] = []
    private var cachedLazyPageCount: Int?
    fileprivate var lastConfiguration: FKPagingConfiguration?
    fileprivate var lastTabConfiguration: FKTabBarConfiguration?

    init(selectedIndex: Binding<Int>) {
      self.selectedIndex = selectedIndex
    }

    fileprivate func cache(from tabs: [FKTabBarItem], pageSource: PageSource) {
      cachedTabs = tabs
      cachedVisibleTabIDs = tabs.filter { !$0.isHidden }.map(\.id)
      switch pageSource {
      case .eager(let pages):
        cachedPageObjectIDs = pages.map { ObjectIdentifier($0) }
        cachedLazyPageCount = nil
      case .lazy(let count, _):
        cachedPageObjectIDs = []
        cachedLazyPageCount = count
      }
    }

    fileprivate func shouldReloadStructure(tabs: [FKTabBarItem], pageSource: PageSource) -> Bool {
      let visibleIDs = tabs.filter { !$0.isHidden }.map(\.id)
      if visibleIDs != cachedVisibleTabIDs { return true }
      switch pageSource {
      case .eager(let pages):
        let ids = pages.map { ObjectIdentifier($0) }
        return ids != cachedPageObjectIDs
      case .lazy(let count, _):
        return count != cachedLazyPageCount
      }
    }

    public func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
      selectedIndex.wrappedValue = index
    }
  }
}
#endif
