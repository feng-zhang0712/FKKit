#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI integration for ``FKPagingController``.
@MainActor
public struct FKPagingControllerRepresentable: UIViewControllerRepresentable {
  public typealias UIViewControllerType = FKPagingController

  private let tabs: [FKTabBarItem]
  private let pageSource: PageSource
  private let tabConfiguration: FKTabBarConfiguration
  private let configuration: FKPagingConfiguration
  @Binding private var selectedIndex: Int
  private var selectedItemID: Binding<String?>?
  private let callbacks: FKPagingControllerRepresentableCallbacks

  fileprivate enum PageSource {
    case eager([UIViewController])
    case lazy(pageCount: Int, provider: (Int) -> UIViewController)
  }

  /// Eager page construction with index binding.
  public init(
    tabs: [FKTabBarItem],
    pages: [UIViewController],
    selectedIndex: Binding<Int>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration(),
    callbacks: FKPagingControllerRepresentableCallbacks = FKPagingControllerRepresentableCallbacks()
  ) {
    self.tabs = tabs
    self.pageSource = .eager(pages)
    self._selectedIndex = selectedIndex
    self.selectedItemID = nil
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
    self.callbacks = callbacks
  }

  /// Lazy page construction with index binding.
  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Binding<Int>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration(),
    callbacks: FKPagingControllerRepresentableCallbacks = FKPagingControllerRepresentableCallbacks()
  ) {
    self.tabs = tabs
    self.pageSource = .lazy(pageCount: pageCount, provider: pageProvider)
    self._selectedIndex = selectedIndex
    self.selectedItemID = nil
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
    self.callbacks = callbacks
  }

  /// Eager page construction with stable tab ID binding.
  public init(
    tabs: [FKTabBarItem],
    pages: [UIViewController],
    selectedItemID: Binding<String?>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration(),
    callbacks: FKPagingControllerRepresentableCallbacks = FKPagingControllerRepresentableCallbacks()
  ) {
    self.tabs = tabs
    self.pageSource = .eager(pages)
    self._selectedIndex = .constant(0)
    self.selectedItemID = selectedItemID
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
    self.callbacks = callbacks
  }

  /// Lazy page construction with stable tab ID binding.
  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedItemID: Binding<String?>,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration(),
    callbacks: FKPagingControllerRepresentableCallbacks = FKPagingControllerRepresentableCallbacks()
  ) {
    self.tabs = tabs
    self.pageSource = .lazy(pageCount: pageCount, provider: pageProvider)
    self._selectedIndex = .constant(0)
    self.selectedItemID = selectedItemID
    self.tabConfiguration = tabConfiguration
    self.configuration = configuration
    self.callbacks = callbacks
  }

  public func makeUIViewController(context: Context) -> FKPagingController {
    let initialIndex: Int
    if let selectedItemID {
      initialIndex = tabs.firstIndex(where: { $0.id == selectedItemID.wrappedValue && !$0.isHidden }) ?? 0
    } else {
      initialIndex = selectedIndex
    }
    let controller: FKPagingController
    switch pageSource {
    case .eager(let pages):
      controller = FKPagingController(
        tabs: tabs,
        viewControllers: pages,
        selectedIndex: initialIndex,
        tabConfiguration: tabConfiguration,
        configuration: configuration
      )
    case .lazy(let count, let provider):
      controller = FKPagingController(
        tabs: tabs,
        pageCount: count,
        pageProvider: provider,
        selectedIndex: initialIndex,
        tabConfiguration: tabConfiguration,
        configuration: configuration
      )
    }
    controller.delegate = context.coordinator
    context.coordinator.cache(from: tabs, pageSource: pageSource)
    context.coordinator.scheduleSelectionBindingSync(from: controller)
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
    let structureSelectedIndex = resolvedStructureSelectedIndex(context: context)
    if coordinator.shouldReloadStructure(tabs: tabs, pageSource: pageSource) {
      switch pageSource {
      case .eager(let pages):
        uiViewController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: structureSelectedIndex)
      case .lazy(let count, let provider):
        uiViewController.setContent(tabs: tabs, pageCount: count, pageProvider: provider, selectedIndex: structureSelectedIndex)
      }
      coordinator.cache(from: tabs, pageSource: pageSource)
    } else if tabs != coordinator.cachedTabs {
      uiViewController.tabBar.reload(items: tabs, updatePolicy: .preserveSelection)
      coordinator.cachedTabs = tabs
    }

    if let selectedItemID {
      if uiViewController.selectedItemID != selectedItemID.wrappedValue,
         let id = selectedItemID.wrappedValue {
        uiViewController.setSelectedIndex(forItemID: id, animated: context.transaction.animation != nil)
      }
    } else if uiViewController.selectedIndex != selectedIndex {
      uiViewController.setSelectedIndex(selectedIndex, animated: context.transaction.animation != nil)
    }
    coordinator.scheduleSelectionBindingSync(from: uiViewController)
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex, selectedItemID: selectedItemID, callbacks: callbacks)
  }

  private func resolvedStructureSelectedIndex(context: Context) -> Int {
    if let selectedItemID,
       let id = selectedItemID.wrappedValue,
       let index = tabs.firstIndex(where: { $0.id == id && !$0.isHidden }) {
      return index
    }
    return selectedIndex
  }

  @MainActor
  public final class Coordinator: NSObject, FKPagingControllerDelegate {
    private var selectedIndex: Binding<Int>
    private var selectedItemID: Binding<String?>?
    private let callbacks: FKPagingControllerRepresentableCallbacks
    fileprivate var cachedTabs: [FKTabBarItem] = []
    private var cachedVisibleTabIDs: [String] = []
    private var cachedPageObjectIDs: [ObjectIdentifier] = []
    private var cachedLazyPageCount: Int?
    fileprivate var lastConfiguration: FKPagingConfiguration?
    fileprivate var lastTabConfiguration: FKTabBarConfiguration?

    init(
      selectedIndex: Binding<Int>,
      selectedItemID: Binding<String?>?,
      callbacks: FKPagingControllerRepresentableCallbacks
    ) {
      self.selectedIndex = selectedIndex
      self.selectedItemID = selectedItemID
      self.callbacks = callbacks
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
        return pages.map { ObjectIdentifier($0) } != cachedPageObjectIDs
      case .lazy(let count, _):
        return count != cachedLazyPageCount
      }
    }

    fileprivate func scheduleSelectionBindingSync(from controller: FKPagingController) {
      let indexBinding = selectedIndex
      let itemIDBinding = selectedItemID
      let index = controller.selectedIndex
      let itemID = controller.selectedItemID
      DispatchQueue.main.async {
        if itemIDBinding != nil {
          guard itemIDBinding?.wrappedValue != itemID else { return }
          itemIDBinding?.wrappedValue = itemID
        } else {
          guard indexBinding.wrappedValue != index else { return }
          indexBinding.wrappedValue = index
        }
      }
    }

    private func emitCallback(_ action: @escaping () -> Void) {
      DispatchQueue.main.async(execute: action)
    }

    public func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
      scheduleSelectionBindingSync(from: controller)
    }

    public func pagingController(
      _ controller: FKPagingController,
      didRequestPageSwitchTo index: Int,
      reason: FKPagingSwitchReason
    ) {
      emitCallback { self.callbacks.onPendingPageIndexChanged?(index) }
    }

    public func pagingControllerDidCancelPendingPageSwitch(_ controller: FKPagingController) {
      emitCallback { self.callbacks.onPendingPageIndexChanged?(nil) }
    }

    public func pagingController(
      _ controller: FKPagingController,
      didUpdateCombinedTransition tabPhase: FKTabBarSwitchPhase,
      pagingPhase: FKPagingPhase,
      progress: CGFloat
    ) {
      let snapshot = controller.stateSnapshot
      if let from = snapshot.fromIndex, let to = snapshot.toIndex {
        emitCallback { self.callbacks.onProgressUpdate?(progress, from, to) }
      }
    }

    public func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase) {
      emitCallback { self.callbacks.onPhaseChanged?(phase) }
    }

    public func pagingController(_ controller: FKPagingController, willDisplayPage viewController: UIViewController, at index: Int) {
      emitCallback { self.callbacks.onWillDisplayPage?(index) }
    }

    public func pagingController(_ controller: FKPagingController, didDisplayPage viewController: UIViewController, at index: Int) {
      emitCallback { self.callbacks.onDidDisplayPage?(index) }
    }

    public func pagingController(_ controller: FKPagingController, didEndDisplayingPage viewController: UIViewController, at index: Int) {
      emitCallback { self.callbacks.onDidEndDisplayingPage?(index) }
    }
  }
}
#endif
