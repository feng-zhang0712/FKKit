import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKMarqueeLabelSwiftUIDemoRoot: View {
  @State private var config = FKMarqueeLabelConfiguration()
  @State private var isPaused = false

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKMarqueeLabelRepresentable(
            configuration: config,
            text: FKMarqueeLabelExampleSupport.sampleLongText,
            isPaused: isPaused
          )
          .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
          .padding(.vertical, 4)
          .background(Color(uiColor: .tertiarySystemFill))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } header: {
          Text("FKMarqueeLabelRepresentable")
        } footer: {
          Text("Wraps FKMarqueeLabel with configuration, text, and isPaused.")
        }

        Section("Control") {
          Toggle("Pause scrolling", isOn: $isPaused)
        }

        Section("Animation") {
          Picker("Direction", selection: Binding(
            get: { config.animation.direction == .left ? 0 : 1 },
            set: { config.animation.direction = $0 == 0 ? .left : .right }
          )) {
            Text("Left").tag(0)
            Text("Right").tag(1)
          }
          .pickerStyle(.segmented)

          Stepper(
            "Speed: \(Int(config.animation.speed)) pt/s",
            value: Binding(
              get: { Double(config.animation.speed) },
              set: { config.animation.speed = CGFloat($0) }
            ),
            in: 12...72,
            step: 6
          )
        }

        Section("Appearance") {
          Picker("Text style", selection: Binding(
            get: { styleTag(for: config.appearance.textStyle) },
            set: { config.appearance.textStyle = styleForTag($0) }
          )) {
            Text("Footnote").tag(0)
            Text("Subheadline").tag(1)
            Text("Body").tag(2)
          }
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
  }

  private func styleTag(for style: UIFont.TextStyle) -> Int {
    switch style {
    case .body: 2
    case .subheadline: 1
    default: 0
    }
  }

  private func styleForTag(_ tag: Int) -> UIFont.TextStyle {
    switch tag {
    case 2: .body
    case 1: .subheadline
    default: .footnote
    }
  }
}

final class FKMarqueeLabelExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"

    let host = UIHostingController(rootView: FKMarqueeLabelSwiftUIDemoRoot())
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

final class FKMarqueeLabelExampleSwiftUIViewController: UIViewController {
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
