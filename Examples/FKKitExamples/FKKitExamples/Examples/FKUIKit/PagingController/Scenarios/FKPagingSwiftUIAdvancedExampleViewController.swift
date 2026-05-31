#if canImport(SwiftUI)
import Combine
import SwiftUI
import UIKit
import FKUIKit

/// SwiftUI bridge with stable ID binding and ``FKPagingControllerRepresentableCallbacks``.
@MainActor
final class FKPagingSwiftUIAdvancedExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI advanced"
    view.backgroundColor = .systemBackground

    var tabs = FKTabBarExampleSupport.makeItems(4)
    tabs[1].badge.state.normal = .count(2)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemMint, titleText: "ID A"),
      FKPagingDemoListViewController(headerTitle: "ID B"),
      FKPagingDemoPageViewController(color: .systemIndigo, titleText: "ID C"),
      FKPagingDemoPageViewController(color: .systemPink, titleText: "ID D"),
    ]

    let root = FKPagingSwiftUIAdvancedDemoView(tabs: tabs, pages: pages)
    let host = UIHostingController(rootView: root)
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

@MainActor
private final class FKPagingSwiftUIAdvancedDemoState: ObservableObject {
  @Published var selectedItemID: String? = "tab-0"
  @Published var pendingIndex: Int?
  @Published var logLines: [String] = []

  lazy var representableCallbacks: FKPagingControllerRepresentableCallbacks = {
    FKPagingControllerRepresentableCallbacks(
      onPendingPageIndexChanged: { [weak self] pending in
        Task { @MainActor [weak self, pending] in
          guard let self else { return }
          self.pendingIndex = pending
          self.appendLog("pending = \(pending.map(String.init) ?? "nil")")
        }
      },
      onProgressUpdate: { [weak self] progress, from, to in
        Task { @MainActor [weak self, progress, from, to] in
          self?.appendLog(String(format: "progress %.2f %d→%d", progress, from, to))
        }
      },
      onPhaseChanged: { [weak self] phase in
        let line = "phase \(phase)"
        Task { @MainActor [weak self, line] in
          self?.appendLog(line)
        }
      },
      onDidDisplayPage: { [weak self] index in
        Task { @MainActor [weak self, index] in
          self?.appendLog("didDisplay @\(index)")
        }
      }
    )
  }()

  init() {}

  private func appendLog(_ line: String) {
    logLines.append(line)
    if logLines.count > 20 {
      logLines.removeFirst(logLines.count - 20)
    }
  }
}

private struct FKPagingSwiftUIAdvancedDemoView: View {
  let tabs: [FKTabBarItem]
  let pages: [UIViewController]

  @StateObject private var state = FKPagingSwiftUIAdvancedDemoState()

  var body: some View {
    VStack(spacing: 0) {
      FKPagingControllerRepresentable(
        tabs: tabs,
        pages: pages,
        selectedItemID: $state.selectedItemID,
        callbacks: state.representableCallbacks
      )

      VStack(alignment: .leading, spacing: 4) {
        Text("selectedItemID = \(state.selectedItemID ?? "nil")")
        Text("pendingPageIndex = \(state.pendingIndex.map(String.init) ?? "nil")")
          .foregroundStyle(.secondary)
        ScrollView {
          Text(state.logLines.suffix(6).joined(separator: "\n"))
            .font(.footnote.monospaced())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 88)
      }
      .font(.footnote)
      .padding(8)
    }
  }
}
#endif
