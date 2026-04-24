#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// SwiftUI wrapper for `FKPagingController`.
@MainActor
public struct FKPagingControllerRepresentable: UIViewControllerRepresentable {
  public typealias UIViewControllerType = FKPagingController

  private let tabs: [FKTabBarItem]
  private let pages: [UIViewController]
  @Binding private var selectedIndex: Int
  private let tabAppearance: FKTabBarAppearance?
  private let tabLayoutOptions: FKTabBarLayoutConfiguration?
  private let tabAnimationOptions: FKTabBarAnimationConfiguration?
  private let configuration: FKPagingConfiguration

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
    self.pages = pages
    self._selectedIndex = selectedIndex
    self.tabAppearance = tabAppearance
    self.tabLayoutOptions = tabLayoutOptions
    self.tabAnimationOptions = tabAnimationOptions
    self.configuration = configuration
  }

  public func makeUIViewController(context: Context) -> FKPagingController {
    let controller = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: selectedIndex,
      tabAppearance: tabAppearance,
      tabLayoutOptions: tabLayoutOptions,
      tabAnimationOptions: tabAnimationOptions,
      configuration: configuration
    )
    controller.delegate = context.coordinator
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKPagingController, context: Context) {
    uiViewController.configuration = configuration
    if uiViewController.selectedIndex != selectedIndex {
      uiViewController.setSelectedIndex(selectedIndex, animated: true)
    }
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(selectedIndex: $selectedIndex)
  }

  @MainActor
  public final class Coordinator: NSObject, FKPagingControllerDelegate {
    private var selectedIndex: Binding<Int>

    init(selectedIndex: Binding<Int>) {
      self.selectedIndex = selectedIndex
    }

    public func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
      selectedIndex.wrappedValue = index
    }
  }
}
#endif
