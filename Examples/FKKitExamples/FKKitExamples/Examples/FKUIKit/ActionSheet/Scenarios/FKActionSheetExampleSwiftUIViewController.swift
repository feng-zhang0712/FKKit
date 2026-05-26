import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKActionSheetExampleSwiftUIViewController: UIViewController {
  private var popoverBarButtonItem: UIBarButtonItem?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    let barButtonItem = UIBarButtonItem(
      title: "Bar popover",
      primaryAction: UIAction { [weak self] _ in
        guard let self, let item = self.popoverBarButtonItem else { return }
        FKActionSheetExamplePlaybook.presentPopover(from: self, barButtonItem: item)
      }
    )
    popoverBarButtonItem = barButtonItem
    navigationItem.rightBarButtonItem = barButtonItem
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
  @State private var showCentered = false
  @State private var showPopover = false
  @State private var popoverAnchor: UIView?
  @State private var statusMessage = "Use buttons to present sheets."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("SwiftUI presents the same FKActionSheet UIViewController as UIKit. Events append to the shared Event log on UIKit scenario pages.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Button("Basic sheet") { showBasics = true }
          .buttonStyle(.borderedProminent)

        Button("Toggle sheet") { showToggle = true }
          .buttonStyle(.bordered)

        Button("Centered card") { showCentered = true }
          .buttonStyle(.bordered)

        FKActionSheetPopoverAnchorButton(title: "Popover (popoverSourceView)") { anchor in
          popoverAnchor = anchor
        } onTap: {
          showPopover = true
        }
        .frame(maxWidth: .infinity, minHeight: 44)

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
    .fkActionSheet(
      isPresented: $showCentered,
      configuration: centeredConfiguration,
      onDismiss: { reason in
        let message = "Centered dismissed: \(String(describing: reason))"
        Task { @MainActor in statusMessage = message }
      }
    )
    .fkActionSheet(
      isPresented: $showPopover,
      configuration: popoverConfiguration,
      popoverSourceView: popoverAnchor,
      onDismiss: { reason in
        let message = "Popover dismissed: \(String(describing: reason))"
        Task { @MainActor in statusMessage = message }
      },
      onPresentFailure: { error in
        let message = "Popover failed: \(error)"
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

  private var centeredConfiguration: FKActionSheetConfiguration {
    FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Centered", message: "Tap outside to dismiss.")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "OK") { }])],
      cancelAction: FKActionSheetAction(title: "Cancel", style: .cancel),
      appearancePreset: .card,
      presentation: .centered
    )
  }

  private var popoverConfiguration: FKActionSheetConfiguration {
    FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "SwiftUI popover")),
      sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Option") { }])],
      cancelAction: FKActionSheetAction(title: "Done", style: .cancel),
      appearancePreset: .plain,
      presentation: .popover
    )
  }
}

/// UIKit anchor surfaced to SwiftUI for popoverSourceView.
private struct FKActionSheetPopoverAnchorButton: UIViewRepresentable {
  let title: String
  let onAnchorReady: (UIView) -> Void
  let onTap: () -> Void

  func makeUIView(context: Context) -> UIButton {
    let button = FKActionSheetExampleUI.anchorButton(title: title)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addAction(UIAction { _ in context.coordinator.onTap() }, for: .touchUpInside)
    return button
  }

  func updateUIView(_ uiView: UIButton, context: Context) {
    context.coordinator.onAnchorReady(uiView)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onAnchorReady: onAnchorReady, onTap: onTap)
  }

  final class Coordinator {
    let onAnchorReady: (UIView) -> Void
    let onTap: () -> Void

    init(onAnchorReady: @escaping (UIView) -> Void, onTap: @escaping () -> Void) {
      self.onAnchorReady = onAnchorReady
      self.onTap = onTap
    }
  }
}
#endif
