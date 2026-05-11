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
  private let tabAppearance: FKTabBarAppearance?
  private let tabLayoutOptions: FKTabBarLayoutConfiguration?
  private let tabAnimationOptions: FKTabBarAnimationConfiguration?
  private let configuration: FKPagingConfiguration
  @Binding private var selectedIndex: Int

  fileprivate enum PageSource {
    case eager([UIViewController])
    case lazy(pageCount: Int, provider: (Int) -> UIViewController)
  }

  /// Eager page construction (mirrors ``FKPagingController/init(tabs:viewControllers:selectedIndex:tabAppearance:tabLayoutOptions:tabAnimationOptions:configuration:)``).
  public init(
    tabs: [FKTabBarItem],
    pages: [UIViewController],
    selectedIndex: Binding<Int>,
    tabAppearance: FKTabBarAppearance? = nil,
    tabLayoutOptions: FKTabBarLayoutConfiguration? = nil,
    tabAnimationOptions: FKTabBarAnimationConfiguration? = nil,
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    self.tabs = tabs
    self.pageSource = .eager(pages)
    self._selectedIndex = selectedIndex
    self.tabAppearance = tabAppearance
    self.tabLayoutOptions = tabLayoutOptions
    self.tabAnimationOptions = tabAnimationOptions
    self.configuration = configuration
  }

  /// Lazy page construction (mirrors ``FKPagingController/init(tabs:pageCount:pageProvider:selectedIndex:tabAppearance:tabLayoutOptions:tabAnimationOptions:configuration:)``).
  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Binding<Int>,
    tabAppearance: FKTabBarAppearance? = nil,
    tabLayoutOptions: FKTabBarLayoutConfiguration? = nil,
    tabAnimationOptions: FKTabBarAnimationConfiguration? = nil,
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    self.tabs = tabs
    self.pageSource = .lazy(pageCount: pageCount, provider: pageProvider)
    self._selectedIndex = selectedIndex
    self.tabAppearance = tabAppearance
    self.tabLayoutOptions = tabLayoutOptions
    self.tabAnimationOptions = tabAnimationOptions
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
        tabAppearance: tabAppearance,
        tabLayoutOptions: tabLayoutOptions,
        tabAnimationOptions: tabAnimationOptions,
        configuration: configuration
      )
    case .lazy(let count, let provider):
      controller = FKPagingController(
        tabs: tabs,
        pageCount: count,
        pageProvider: provider,
        selectedIndex: selectedIndex,
        tabAppearance: tabAppearance,
        tabLayoutOptions: tabLayoutOptions,
        tabAnimationOptions: tabAnimationOptions,
        configuration: configuration
      )
    }
    controller.delegate = context.coordinator
    context.coordinator.cache(from: tabs, pageSource: pageSource)
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKPagingController, context: Context) {
    uiViewController.configuration = configuration
    let coordinator = context.coordinator
    if coordinator.shouldReload(tabs: tabs, pageSource: pageSource) {
      switch pageSource {
      case .eager(let pages):
        uiViewController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: selectedIndex)
      case .lazy(let count, let provider):
        uiViewController.setContent(tabs: tabs, pageCount: count, pageProvider: provider, selectedIndex: selectedIndex)
      }
      coordinator.cache(from: tabs, pageSource: pageSource)
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
    private var cachedTabs: [FKTabBarItem] = []
    private var cachedPageObjectIDs: [ObjectIdentifier] = []
    private var cachedLazyPageCount: Int?

    init(selectedIndex: Binding<Int>) {
      self.selectedIndex = selectedIndex
    }

    fileprivate func cache(from tabs: [FKTabBarItem], pageSource: PageSource) {
      cachedTabs = tabs
      switch pageSource {
      case .eager(let pages):
        cachedPageObjectIDs = pages.map { ObjectIdentifier($0) }
        cachedLazyPageCount = nil
      case .lazy(let count, _):
        cachedPageObjectIDs = []
        cachedLazyPageCount = count
      }
    }

    fileprivate func shouldReload(tabs: [FKTabBarItem], pageSource: PageSource) -> Bool {
      guard tabs == cachedTabs else { return true }
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
