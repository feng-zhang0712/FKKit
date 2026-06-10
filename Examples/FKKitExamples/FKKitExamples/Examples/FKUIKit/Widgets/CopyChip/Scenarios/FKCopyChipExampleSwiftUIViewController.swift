import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKCopyChipSwiftUIDemoRoot: View {
  @State private var config = FKCopyChipConfiguration()
  @State private var lastCopied: String?

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKCopyChipRepresentable(
            configuration: config,
            text: "SWIFT-UI-42",
            copyText: "SWIFT-UI-42-extended-token",
            onCopy: { copied in lastCopied = copied }
          )
          .fixedSize(horizontal: true, vertical: false)
          .frame(minHeight: 44)
        } header: {
          Text("FKCopyChipRepresentable")
        } footer: {
          Text("Wraps FKCopyChip with configuration, text/copyText, and onCopy callback.")
        }

        if let lastCopied {
          Section("Last copied") {
            Text(lastCopied)
              .font(.footnote.monospaced())
              .foregroundStyle(.secondary)
          }
        }

        Section("Feedback") {
          Picker("Mode", selection: Binding(
            get: { feedbackTag(for: config.feedback.mode) },
            set: { config.feedback.mode = feedbackMode(for: $0) }
          )) {
            Text("Toast").tag(0)
            Text("Haptic").tag(1)
            Text("None").tag(2)
          }
          .pickerStyle(.segmented)
        }

        Section("Layout") {
          Picker("Size", selection: Binding(
            get: { config.layout.size == .s ? 0 : 1 },
            set: { config.layout.size = $0 == 0 ? .s : .m }
          )) {
            Text("S").tag(0)
            Text("M").tag(1)
          }
          .pickerStyle(.segmented)

          Toggle("Monospaced", isOn: Binding(
            get: { config.appearance.usesMonospacedFont },
            set: { config.appearance.usesMonospacedFont = $0 }
          ))
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
  }

  private func feedbackTag(for mode: FKCopyChipFeedback) -> Int {
    switch mode {
    case .toast: 0
    case .hapticOnly: 1
    case .none: 2
    }
  }

  private func feedbackMode(for tag: Int) -> FKCopyChipFeedback {
    switch tag {
    case 1: .hapticOnly
    case 2: .none
    default: .toast
    }
  }
}

final class FKCopyChipExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"

    let host = UIHostingController(rootView: FKCopyChipSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
  }
}
#endif

#if !canImport(SwiftUI)
import UIKit

final class FKCopyChipExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = "SwiftUI is unavailable in this build configuration."
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
#endif
