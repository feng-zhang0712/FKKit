#if canImport(SwiftUI)
import SwiftUI
import UIKit
import FKUIKit

/// Lazy provider bridged through SwiftUI with the dedicated initializer.
@MainActor
final class FKPagingLazySwiftUIExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI lazy"
    view.backgroundColor = .systemBackground

    let tabs = FKTabBarExampleSupport.makeItems(6)
    let root = UIHostingController(
      rootView: FKPagingLazySwiftUIDemoView(tabs: tabs)
    )
    addChild(root)
    root.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(root.view)
    root.didMove(toParent: self)

    NSLayoutConstraint.activate([
      root.view.topAnchor.constraint(equalTo: view.topAnchor),
      root.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      root.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      root.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

private struct FKPagingLazySwiftUIDemoView: View {
  let tabs: [FKTabBarItem]
  @State private var selectedIndex = 0

  var body: some View {
    FKPagingControllerRepresentable(
      tabs: tabs,
      pageCount: tabs.filter { !$0.isHidden }.count,
      pageProvider: { index in
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink, .systemYellow]
        let color = colors[index % colors.count]
        return FKPagingDemoPageViewController(color: color, titleText: "Lazy SwiftUI \(index)")
      },
      selectedIndex: $selectedIndex,
      configuration: FKPagingConfiguration(
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1)
      )
    )
  }
}
#endif
