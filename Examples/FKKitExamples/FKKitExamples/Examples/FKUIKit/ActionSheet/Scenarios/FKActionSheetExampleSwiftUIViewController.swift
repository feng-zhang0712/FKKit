import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKActionSheetExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKActionSheetSwiftUIExampleSurface())
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
    let label = UILabel()
    label.text = "SwiftUI is unavailable in this build."
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKActionSheetSwiftUIExampleSurface: View {
  @State private var showBasics = false
  @State private var showToggle = false
  @State private var statusMessage = "Use buttons to present sheets."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("SwiftUI uses the same FKActionSheet implementation as UIKit. Events are logged in the Handlers page when you navigate back.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Button("Basic sheet") { showBasics = true }
          .buttonStyle(.borderedProminent)

        Button("Toggle sheet") { showToggle = true }
          .buttonStyle(.bordered)

        Button("Clear status") { statusMessage = "Cleared." }
          .buttonStyle(.borderless)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .fkActionSheet(
      isPresented: $showBasics,
      title: "SwiftUI Sheet",
      message: "Presented via View.fkActionSheet",
      actions: [
        FKActionSheetAction(title: "Confirm") {
          FKActionSheetExamplePlaybook.log("SwiftUI confirm")
        },
      ],
      onDismiss: { reason in
        let message = "Basics dismissed: \(String(describing: reason))"
        Task { @MainActor in statusMessage = message }
      },
      onPresentFailure: { error in
        let message = "Present failed: \(error)"
        Task { @MainActor in statusMessage = message }
      }
    )
    .fkActionSheet(
      isPresented: $showToggle,
      configuration: toggleConfiguration,
      onDismiss: { reason in
        let message = "Toggle dismissed: \(String(describing: reason))"
        Task { @MainActor in statusMessage = message }
      }
    )
  }

  private var toggleConfiguration: FKActionSheetConfiguration {
    FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "SwiftUI toggle")),
      sections: [
        FKActionSheetSection(actions: [
          FKActionSheetAction.toggle(title: "Include metadata", isOn: true) { isOn in
            FKActionSheetExamplePlaybook.log("SwiftUI toggle = \(isOn)")
          },
        ]),
      ],
      cancelAction: FKActionSheetAction(title: "Done", style: .cancel)
    )
  }
}
#endif
