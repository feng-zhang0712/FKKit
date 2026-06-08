import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKWebViewSwiftUIExampleRoot: View {
  private let pages: [(title: String, url: URL)] = [
    ("Example.com", FKWebViewExampleURLs.remoteHTTPS),
    ("404 error", FKWebViewExampleURLs.http404),
  ]

  @State private var selectedIndex = 0
  @State private var eventLog = ""

  var body: some View {
    VStack(spacing: 0) {
      Picker("Page", selection: $selectedIndex) {
        ForEach(pages.indices, id: \.self) { index in
          Text(pages[index].title).tag(index)
        }
      }
      .pickerStyle(.segmented)
      .padding()

      Text("404 should show the error empty state overlay, not a blank page.")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)

      FKWebViewRepresentable(
        url: pages[selectedIndex].url,
        configuration: FKWebViewConfiguration(),
        callbacks: FKWebViewCallbacks(
          onStateChange: { state in
            eventLog += "state: \(String(describing: state))\n"
          },
          onFinish: { url in
            eventLog += "finish: \(url?.absoluteString ?? "nil")\n"
          },
          onFail: { error in
            eventLog += "fail: \(error)\n"
          }
        )
      )

      Text(eventLog)
        .font(.caption.monospaced())
        .frame(maxWidth: .infinity, maxHeight: 120, alignment: .topLeading)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
    }
    .navigationTitle("SwiftUI")
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// ``FKWebViewRepresentable`` with binding-driven URL reload.
final class FKWebViewExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    let hosting = UIHostingController(rootView: NavigationView { FKWebViewSwiftUIExampleRoot() })
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hosting.didMove(toParent: self)
  }
}
#else
final class FKWebViewExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI"
    view.backgroundColor = .systemBackground
  }
}
#endif
