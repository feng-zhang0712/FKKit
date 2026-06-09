import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKSearchSwiftUIDemoRoot: View {
  @State private var barText = ""
  @State private var fieldText = ""
  @State private var isLoading = false
  @State private var barConfiguration = FKSearchBarDefaults.inlineCard()
  @State private var fieldConfiguration = FKSearchFieldDefaults.compactFilter()
  @State private var logLines: [String] = []

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKSearchBarRepresentable(
            text: $barText,
            configuration: barConfiguration,
            placeholder: "FKSearchBar",
            isLoading: isLoading,
            onSearchQueryChanged: { query in append("bar query → \(query)") },
            onSubmit: { query in append("bar submit → \(query)") }
          )
          .frame(minHeight: 44)

          FKSearchFieldRepresentable(
            text: $fieldText,
            configuration: fieldConfiguration,
            placeholder: "FKSearchField",
            isLoading: isLoading,
            onSearchQueryChanged: { query in append("field query → \(query)") }
          )
          .frame(minHeight: 40)
        } header: {
          Text("Representables")
        } footer: {
          Text("Bindings sync with suppressEvents to avoid feedback loops.")
        }

        Section("State") {
          Toggle("Loading", isOn: $isLoading)
          Button("Set bar text programmatically") {
            barText = "camera"
          }
          Button("Set field text programmatically") {
            fieldText = "keyboard"
          }
        }

        Section("Event log") {
          if logLines.isEmpty {
            Text("Interact with the controls above.")
              .foregroundStyle(.secondary)
          } else {
            ForEach(Array(logLines.enumerated()), id: \.offset) { _, line in
              Text(line).font(.caption.monospaced())
            }
          }
        }
      }
      .navigationTitle("SwiftUI")
    }
    .navigationViewStyle(.stack)
  }

  private func append(_ line: String) {
    logLines.insert(line, at: 0)
    if logLines.count > 12 { logLines.removeLast() }
  }
}
#endif

/// Hosts ``FKSearchBarRepresentable`` and ``FKSearchFieldRepresentable``.
final class FKSearchExampleSwiftUIViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    title = "SwiftUI bridge"
    let host = UIHostingController(rootView: FKSearchSwiftUIDemoRoot())
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
    title = "SwiftUI"
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "SwiftUI is not available in this build."
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
#endif
  }
}
