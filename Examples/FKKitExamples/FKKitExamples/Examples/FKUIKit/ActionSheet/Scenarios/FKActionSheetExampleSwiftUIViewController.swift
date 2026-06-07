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
  @State private var showLoading = false
  @State private var showPopover = false
  @State private var loadingConfiguration = FKActionSheetConfiguration.loading(
    .standard(
      FKActionSheetStandardLoadingContent(
        title: "Loading options",
        message: "SwiftUI binding will swap configuration when fetch completes."
      )
    ),
    preferredPanelHeight: 180,
    cancelAction: FKActionSheetAction(title: "Cancel", style: .cancel)
  )
  @State private var popoverAnchor: UIView?
  @State private var statusMessage = "Events also appear on UIKit scenario pages (shared log)."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("SwiftUI presents the same FKActionSheet UIViewController as UIKit. Keep isPresented true and replace configuration to finish loading.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Group {
          Button("Basic sheet") { showBasics = true }
            .buttonStyle(.borderedProminent)

          Button("Toggle sheet") { showToggle = true }
            .buttonStyle(.bordered)

          Button("Centered card") { showCentered = true }
            .buttonStyle(.bordered)

          Button("Loading → fetch (binding)") {
            loadingConfiguration = Self.makeLoadingConfiguration()
            showLoading = true
            startSwiftUILoadingFetch()
          }
          .buttonStyle(.bordered)

          FKActionSheetPopoverAnchorButton(title: "Popover (popoverSourceView)") { anchor in
            popoverAnchor = anchor
          } onTap: {
            showPopover = true
          }
          .frame(maxWidth: .infinity, minHeight: 44)
        }

        Button("Clear status") { statusMessage = "Cleared." }
          .buttonStyle(.borderless)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .fk_actionSheet(
      isPresented: $showBasics,
      title: "SwiftUI Sheet",
      message: "Presented via View.fk_actionSheet",
      actions: [
        FKActionSheetAction(title: "Confirm") {
          FKActionSheetExamplePlaybook.log("SwiftUI confirm")
        },
      ],
      onDismiss: { reason in
        statusMessage = "Basics dismissed: \(String(describing: reason))"
      },
      onPresentFailure: { error in
        statusMessage = "Present failed: \(error)"
      }
    )
    .fk_actionSheet(
      isPresented: $showToggle,
      configuration: toggleConfiguration,
      onDismiss: { reason in
        statusMessage = "Toggle dismissed: \(String(describing: reason))"
      }
    )
    .fk_actionSheet(
      isPresented: $showCentered,
      configuration: centeredConfiguration,
      onDismiss: { reason in
        statusMessage = "Centered dismissed: \(String(describing: reason))"
      }
    )
    .fk_actionSheet(
      isPresented: $showLoading,
      configuration: loadingConfiguration,
      onDismiss: { reason in
        statusMessage = "Loading flow dismissed: \(String(describing: reason))"
      },
      onPresentFailure: { error in
        statusMessage = "Loading present failed: \(error)"
      }
    )
    .fk_actionSheet(
      isPresented: $showPopover,
      configuration: popoverConfiguration,
      popoverSourceView: popoverAnchor,
      onDismiss: { reason in
        statusMessage = "Popover dismissed: \(String(describing: reason))"
      },
      onPresentFailure: { error in
        statusMessage = "Popover failed: \(error)"
      }
    )
  }

  private static func makeLoadingConfiguration() -> FKActionSheetConfiguration {
    FKActionSheetConfiguration.loading(
      .standard(
        FKActionSheetStandardLoadingContent(
          title: "Loading options",
          message: "SwiftUI binding will swap configuration when fetch completes."
        )
      ),
      preferredPanelHeight: 180,
      cancelAction: FKActionSheetAction(title: "Cancel", style: .cancel)
    )
  }

  private func startSwiftUILoadingFetch() {
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard showLoading else { return }
      loadingConfiguration = FKActionSheetConfiguration(
        header: .text(FKActionSheetHeader(title: "Share", message: "Loaded via configuration binding")),
        sections: [
          FKActionSheetSection(actions: [
            FKActionSheetAction(title: "Messages") {
              FKActionSheetExamplePlaybook.log("SwiftUI Messages")
            },
          ]),
        ],
        cancelAction: FKActionSheetAction(title: "Cancel", style: .cancel),
        appearance: loadingConfiguration.appearance,
        presentation: loadingConfiguration.presentation
      )
      FKActionSheetExamplePlaybook.log("SwiftUI configuration → actions after fetch")
      statusMessage = "Loading configuration replaced with action rows."
    }
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
