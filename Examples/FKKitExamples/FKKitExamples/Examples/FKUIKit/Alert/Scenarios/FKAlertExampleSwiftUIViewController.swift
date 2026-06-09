import FKCoreKit
import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKAlertExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKAlertSwiftUIExampleSurface())
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
private struct FKAlertSwiftUIExampleSurface: View {
  @State private var showConfirm = false
  @State private var showPrompt = false
  @State private var showDestructive = false
  @State private var statusMessage = "Tap a button to present an alert."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("SwiftUI uses the same FKAlertPresenter as UIKit via View.fkAlert(isPresented:content:onResult:).")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        Button("Confirm alert") { showConfirm = true }
          .buttonStyle(.borderedProminent)
        Button("Text field prompt") { showPrompt = true }
          .buttonStyle(.bordered)
        Button("Destructive delete") { showDestructive = true }
          .buttonStyle(.bordered)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .fkAlert(
      isPresented: $showConfirm,
      content: FKAlertContent(
        title: "Sign out?",
        message: "You can sign in again at any time.",
        actions: [
          FKAlertAction(title: "Sign out", style: .default),
          FKAlertAction(title: "Cancel", style: .cancel),
        ]
      ),
      onResult: { result in
        statusMessage = "Confirm → \(FKAlertExampleLog.describe(result))"
        FKAlertExampleLog.log("SwiftUI confirm: \(FKAlertExampleLog.describe(result))")
      }
    )
    .fkAlert(
      isPresented: $showPrompt,
      content: FKAlertExamplePlaybook.renamePromptContent(initial: "SwiftUI playlist"),
      configuration: FKAlertPresets.textPrompt(),
      onResult: { result in
        statusMessage = "Prompt → \(FKAlertExampleLog.describe(result))"
        FKAlertExampleLog.log("SwiftUI prompt: \(FKAlertExampleLog.describe(result))")
      }
    )
    .fkAlert(
      isPresented: $showDestructive,
      content: FKAlertExamplePlaybook.destructiveDeleteContent(),
      configuration: FKAlertPresets.destructiveConfirm(),
      onResult: { result in
        statusMessage = "Destructive → \(FKAlertExampleLog.describe(result))"
        FKAlertExampleLog.log("SwiftUI destructive: \(FKAlertExampleLog.describe(result))")
      }
    )
  }
}
#endif
