#if canImport(SwiftUI)
import SwiftUI
import UIKit
import FKUIKit

/// Hosts ``FKPagingControllerRepresentable`` inside a UIKit navigation stack.
@MainActor
final class FKPagingSwiftUIBridgeExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemBackground

    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBrown, titleText: "SwiftUI A"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "SwiftUI B"),
      FKPagingDemoListViewController(headerTitle: "SwiftUI C"),
      FKPagingDemoPageViewController(color: .systemCyan, titleText: "SwiftUI D"),
    ]

    let bindingDemo = FKPagingSwiftUIDemoView(tabs: tabs, pages: pages)
    let host = UIHostingController(rootView: bindingDemo)
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    host.didMove(toParent: self)

    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

private struct FKPagingSwiftUIDemoView: View {
  let tabs: [FKTabBarItem]
  let pages: [UIViewController]
  @State private var selectedIndex = 0

  var body: some View {
    VStack(spacing: 0) {
      FKPagingControllerRepresentable(
        tabs: tabs,
        pages: pages,
        selectedIndex: $selectedIndex,
        configuration: FKPagingConfiguration(
          tabBarHeight: 48,
          allowsSwipePaging: true,
          preloadRange: 0,
          retentionPolicy: .keepAll,
          gesturePolicy: .exclusive,
          tabAlignment: .followTabBarDefault
        )
      )
      Text("selectedIndex = \(selectedIndex)")
        .font(.footnote.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }
  }
}
#endif
