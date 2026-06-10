import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKStatusPillSwiftUIDemoRoot: View {
  @State private var config = FKStatusPillConfiguration()
  @State private var styleIndex = 3
  @State private var showsDot = true

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKStatusPillView(
            configuration: config,
            title: "Out for delivery",
            style: resolvedStyle(),
            showsDot: showsDot
          )
        } header: {
          Text("FKStatusPillView")
        } footer: {
          Text("Native SwiftUI pill mirroring FKStatusPill colors, layout tokens, and accessibility.")
        }

        Section("Style") {
          Picker("Style", selection: $styleIndex) {
            Text("Success").tag(0)
            Text("Warning").tag(1)
            Text("Error").tag(2)
            Text("Info").tag(3)
            Text("Neutral").tag(4)
          }
        }

        Section("Layout") {
          Toggle("Leading dot", isOn: $showsDot)
          Picker("Size", selection: Binding(
            get: { config.layout.size == .s ? 0 : 1 },
            set: { config.layout.size = $0 == 0 ? .s : .m }
          )) {
            Text("S (28 pt)").tag(0)
            Text("M (32 pt)").tag(1)
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
  }

  private func resolvedStyle() -> FKStatusPillStyle {
    switch styleIndex {
    case 0: .success
    case 1: .warning
    case 2: .error
    case 4: .neutral
    default: .info
    }
  }
}

final class FKStatusPillExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"

    let host = UIHostingController(rootView: FKStatusPillSwiftUIDemoRoot())
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

final class FKStatusPillExampleSwiftUIViewController: UIViewController {
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
