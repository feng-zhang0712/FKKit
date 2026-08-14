import FKUIKit
import SwiftUI
import UIKit

/// SwiftUI wrappers for checkbox, radio button, and radio group.
final class FKSelectionExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemGroupedBackground

    let host = UIHostingController(rootView: FKSelectionExampleSwiftUIRoot())
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
  }
}

private struct FKSelectionExampleSwiftUIRoot: View {
  @State private var checkState: FKCheckboxState = .unchecked
  @State private var radioSelected = false
  @State private var selectedOptionID: FKRadioOptionID? = "month"
  @State private var linkText = "—"

  private let options = FKSelectionExampleSupport.billingOptions()

  var body: some View {
    Form {
      Section("FKCheckboxRepresentable") {
        FKCheckboxRepresentable(
          checkState: $checkState,
          content: .init(title: "Enable reminders"),
          onStateChanged: { _ in }
        )
        .frame(minHeight: 44)
        Text("State: \(String(describing: checkState))")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("FKRadioButtonRepresentable") {
        FKRadioButtonRepresentable(
          isSelected: $radioSelected,
          content: .init(title: "Standalone radio")
        )
        .frame(minHeight: 44)
        Text(radioSelected ? "Selected" : "Not selected")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("FKRadioGroupRepresentable") {
        FKRadioGroupRepresentable(
          selectedOptionID: $selectedOptionID,
          options: options
        )
        .frame(minHeight: 160)
        Text("Selected: \(selectedOptionID ?? "nil")")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      Section("Agreement link") {
        FKCheckboxRepresentable(
          checkState: $checkState,
          configuration: FKCheckboxPresets.agreement(),
          content: {
            var text = AttributedString("I agree to the ")
            var link = AttributedString("Terms")
            link.link = URL(string: "https://example.com/terms")
            text.append(link)
            return .init(attributedTitle: text, isRequired: true)
          }(),
          onLinkActivated: { url in
            linkText = url.absoluteString
          }
        )
        .frame(minHeight: 64)
        Text("Last link: \(linkText)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }
}
