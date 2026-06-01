#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper for `FKTabBar`.
///
/// Selection sync rules:
/// - User taps update the binding via `onSelectionChanged`.
/// - When the visible strip’s item-ID sequence changes (add/remove/reorder/hidden toggles), the binding is updated from the UIKit control so it tracks `reload` policies (`preserveSelection`, etc.).
/// - Programmatic binding updates apply with `notify: false` to avoid feedback loops and spurious delegate callbacks.
@MainActor
public struct FKTabBarRepresentable: UIViewRepresentable {
  public typealias UIViewType = FKTabBar

  private let items: [FKTabBarItem]
  @Binding private var selectedIndex: Int
  private var selectionProgress: Binding<FKTabBarSelectionProgress?>?
  private let configuration: FKTabBarConfiguration
  private let selectionControlMode: FKTabBar.SelectionControlMode
  private let customization: FKTabBarCustomization?
  private let onSelectionRequest: ((FKTabBarItem, Int) -> Void)?
  private let onSelectionProgress: ((Int, Int, CGFloat) -> Void)?

  /// Creates a SwiftUI bridge for `FKTabBar`.
  ///
  /// - Important: Keep item IDs stable across updates so selection preservation can work correctly.
  public init(
    items: [FKTabBarItem],
    selectedIndex: Binding<Int>,
    configuration: FKTabBarConfiguration = FKTabBarDefaults.defaultConfiguration,
    selectionControlMode: FKTabBar.SelectionControlMode = .uncontrolled,
    customization: FKTabBarCustomization? = nil,
    onSelectionRequest: ((FKTabBarItem, Int) -> Void)? = nil,
    onSelectionProgress: ((Int, Int, CGFloat) -> Void)? = nil
  ) {
    self.items = items
    self._selectedIndex = selectedIndex
    self.selectionProgress = nil
    self.configuration = configuration
    self.selectionControlMode = selectionControlMode
    self.customization = customization
    self.onSelectionRequest = onSelectionRequest
    self.onSelectionProgress = onSelectionProgress
  }

  /// Creates a SwiftUI bridge with an optional interactive progress binding.
  public init(
    items: [FKTabBarItem],
    selectedIndex: Binding<Int>,
    selectionProgress: Binding<FKTabBarSelectionProgress?>,
    configuration: FKTabBarConfiguration = FKTabBarDefaults.defaultConfiguration,
    selectionControlMode: FKTabBar.SelectionControlMode = .uncontrolled,
    customization: FKTabBarCustomization? = nil,
    onSelectionRequest: ((FKTabBarItem, Int) -> Void)? = nil,
    onSelectionProgress: ((Int, Int, CGFloat) -> Void)? = nil
  ) {
    self.items = items
    self._selectedIndex = selectedIndex
    self.selectionProgress = selectionProgress
    self.configuration = configuration
    self.selectionControlMode = selectionControlMode
    self.customization = customization
    self.onSelectionRequest = onSelectionRequest
    self.onSelectionProgress = onSelectionProgress
  }

  public func makeUIView(context: Context) -> FKTabBar {
    let view = FKTabBar(items: items, selectedIndex: selectedIndex, configuration: configuration)
    configure(view, context: context)
    context.coordinator.lastVisibleItemIDs = items.filter { !$0.isHidden }.map(\.id)
    context.coordinator.lastItems = items
    return view
  }

  public func updateUIView(_ uiView: FKTabBar, context: Context) {
    configure(uiView, context: context)

    let itemsChanged = items != context.coordinator.lastItems
    if itemsChanged {
      uiView.reload(items: items, updatePolicy: .preserveSelection)
      context.coordinator.lastItems = items
      context.coordinator.lastVisibleItemIDs = items.filter { !$0.isHidden }.map(\.id)
      if context.coordinator.selectedIndex.wrappedValue != uiView.selectedIndex {
        context.coordinator.selectedIndex.wrappedValue = uiView.selectedIndex
      }
      return
    }

    if uiView.selectedIndex != selectedIndex {
      uiView.setSelectedIndex(selectedIndex, animated: true, notify: false, reason: .programmatic)
    }

    if let selectionProgress {
      let value = selectionProgress.wrappedValue
      if value != context.coordinator.lastSelectionProgress {
        context.coordinator.lastSelectionProgress = value
        if let value {
          uiView.setSelectionProgress(from: value.fromIndex, to: value.toIndex, progress: value.progress)
        }
      }
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex, selectionProgress: selectionProgress)
  }

  private func configure(_ view: FKTabBar, context: Context) {
    if context.coordinator.lastConfiguration != configuration {
      view.configuration = configuration
      context.coordinator.lastConfiguration = configuration
    }
    view.selectionControlMode = selectionControlMode
    view.customization = customization
    view.onSelectionChanged = { _, index, _ in
      context.coordinator.selectedIndex.wrappedValue = index
    }
    view.onSelectionRequest = onSelectionRequest
    view.onSelectionProgress = { from, to, progress in
      onSelectionProgress?(from, to, progress)
      let snapshot = FKTabBarSelectionProgress(fromIndex: from, toIndex: to, progress: progress)
      context.coordinator.selectionProgress?.wrappedValue = snapshot
      context.coordinator.lastSelectionProgress = snapshot
    }
  }

  @MainActor
  public final class Coordinator {
    fileprivate var selectedIndex: Binding<Int>
    fileprivate var selectionProgress: Binding<FKTabBarSelectionProgress?>?
    /// Used to detect visible-strip structural changes so selection can sync tab bar → SwiftUI without fighting valid binding updates.
    fileprivate var lastVisibleItemIDs: [String] = []
    fileprivate var lastItems: [FKTabBarItem] = []
    fileprivate var lastSelectionProgress: FKTabBarSelectionProgress?
    fileprivate var lastConfiguration: FKTabBarConfiguration?

    init(selectedIndex: Binding<Int>, selectionProgress: Binding<FKTabBarSelectionProgress?>?) {
      self.selectedIndex = selectedIndex
      self.selectionProgress = selectionProgress
    }
  }
}
#endif
