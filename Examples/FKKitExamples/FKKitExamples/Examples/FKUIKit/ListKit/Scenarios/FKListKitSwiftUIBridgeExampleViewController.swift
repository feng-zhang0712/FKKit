import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKListKitSwiftUIDemoRoot: View {
  var body: some View {
    FKDiffableTableViewControllerRepresentable(
      configuration: {
        var config = FKListDefaults.feedConfiguration
        config.refresh.isPullToRefreshEnabled = false
        config.refresh.isLoadMoreEnabled = false
        return config
      }(),
      makeViewController: { configuration, style in
        let controller = FKListKitSwiftUIBridgeHostViewController(configuration: configuration, style: style)
        return controller
      }
    )
    .ignoresSafeArea(edges: .bottom)
  }
}

/// Host VC that applies a static snapshot for the SwiftUI bridge demo.
private final class FKListKitSwiftUIBridgeHostViewController: FKDiffableTableViewController {
  override init(configuration: FKListConfiguration, style: UITableView.Style) {
    super.init(configuration: configuration, style: style)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let items = (1 ... 12).map { index in
      FKListItem.subtitle(
        id: FKListItemID("swiftui-\(index)"),
        title: "SwiftUI row \(index)",
        subtitle: "FKDiffableTableViewControllerRepresentable"
      )
    }
    applySnapshot(FKListSnapshot(items: items), animatingDifferences: false)
  }
}
#endif

/// Demonstrates ``FKDiffableTableViewControllerRepresentable``.
final class FKListKitSwiftUIBridgeExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
#if canImport(SwiftUI)
    title = "SwiftUI Bridge"
    let host = UIHostingController(rootView: FKListKitSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
#else
    title = "SwiftUI Unavailable"
#endif
  }
}
