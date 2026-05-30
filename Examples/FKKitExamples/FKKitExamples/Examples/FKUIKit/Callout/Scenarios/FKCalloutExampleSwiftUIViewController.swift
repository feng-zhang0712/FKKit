import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// SwiftUI triggers FKTooltip and FKPopover using the library anchor bridge.
final class FKCalloutExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemGroupedBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKCalloutSwiftUIExampleSurface())
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
private struct FKCalloutSwiftUIExampleSurface: View {
  @StateObject private var anchorBox = FKCalloutSwiftUIAnchorBox()
  @State private var statusMessage = "Uses FKCalloutSwiftUIAnchorButton from FKUIKit."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("SwiftUI calls FKTooltip and FKPopover directly. Use FKCalloutSwiftUIAnchorBox to hold the UIKit anchor reference.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        FKCalloutSwiftUIAnchorButton(title: "SwiftUI anchor", anchorBox: anchorBox)
          .frame(maxWidth: .infinity, minHeight: 44)

        Button("Show tooltip (top)") {
          presentTooltip()
        }
        .buttonStyle(.borderedProminent)

        Button("Show coach mark") {
          presentCoachMark()
        }
        .buttonStyle(.bordered)

        Button("Dismiss active") {
          FKPopover.dismissActive()
          statusMessage = "Dismissed active callout."
        }
        .buttonStyle(.borderless)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
  }

  private func presentTooltip() {
    guard let anchor = anchorBox.view else {
      statusMessage = "Anchor not ready."
      return
    }
    guard FKTooltip.show("SwiftUI tooltip", anchoredTo: anchor, placement: .top) != nil else {
      statusMessage = "Could not present tooltip (anchor not in a window)."
      return
    }
    statusMessage = "FKTooltip.show · .top"
  }

  private func presentCoachMark() {
    guard let anchor = anchorBox.view else {
      statusMessage = "Anchor not ready."
      return
    }
    guard FKPopover.showCoachMark(
      FKCalloutCoachMarkContent(
        title: "SwiftUI bridge",
        message: "Present coach marks from SwiftUI using a UIKit anchor.",
        showsCloseButton: true
      ),
      anchoredTo: anchor,
      placement: .bottom,
      primaryAction: {
        FKPopover.dismissActive()
      }
    ) != nil else {
      statusMessage = "Could not present coach mark (anchor not in a window)."
      return
    }
    statusMessage = "FKPopover.showCoachMark · backdrop spotlight"
  }
}
#endif
