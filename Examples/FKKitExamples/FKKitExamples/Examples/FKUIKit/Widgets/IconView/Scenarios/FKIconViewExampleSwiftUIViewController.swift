import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKIconViewSwiftUIDemoRoot: View {
  @State private var config = FKIconViewConfiguration()
  @State private var tintChoice = 0

  var body: some View {
    NavigationView {
      Form {
        Section {
          HStack(spacing: 24) {
            FKIconViewRepresentable(
              configuration: config,
              symbolName: "globe.americas.fill",
              tintColor: resolvedTint()
            )
            FKIconViewRepresentable(
              configuration: badgeConfig,
              symbolName: "tray.fill",
              tintColor: .systemBlue
            )
            .overlay(alignment: .topTrailing) {
              Text("3")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.red))
                .offset(x: 6, y: -4)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 8)
        } header: {
          Text("FKIconViewRepresentable")
        } footer: {
          Text("Wraps FKIconView with configuration, symbolName, image, and tintColor. Badge overlay shown for composition — attach fk_badge in UIKit hosts.")
        }

        Section("Layout") {
          Picker("Size", selection: Binding(
            get: { sizeTag(for: config.layout.size) },
            set: { config.layout.size = sizeForTag($0) }
          )) {
            Text("S").tag(0)
            Text("M").tag(1)
            Text("L").tag(2)
          }
          .pickerStyle(.segmented)
        }

        Section("Appearance") {
          Picker("Background", selection: Binding(
            get: { backgroundTag(for: config.appearance.backgroundStyle) },
            set: { config.appearance.backgroundStyle = backgroundForTag($0) }
          )) {
            Text("None").tag(0)
            Text("Circle").tag(1)
          }
          .pickerStyle(.segmented)

          Picker("Tint", selection: $tintChoice) {
            Text("Green").tag(0)
            Text("Orange").tag(1)
            Text("Purple").tag(2)
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
  }

  private var badgeConfig: FKIconViewConfiguration {
    var cfg = FKIconViewConfiguration()
    cfg.layout.size = .m
    cfg.appearance.backgroundStyle = .circle(fill: UIColor.systemBlue.withAlphaComponent(0.12))
    return cfg
  }

  private func resolvedTint() -> UIColor {
    switch tintChoice {
    case 1: .systemOrange
    case 2: .systemPurple
    default: .systemGreen
    }
  }

  private func sizeTag(for size: FKIconViewSize) -> Int {
    switch size {
    case .s: 0
    case .m: 1
    case .l: 2
    }
  }

  private func sizeForTag(_ tag: Int) -> FKIconViewSize {
    switch tag {
    case 0: .s
    case 2: .l
    default: .m
    }
  }

  private func backgroundTag(for style: FKIconViewBackgroundStyle) -> Int {
    if case .none = style { 0 } else { 1 }
  }

  private func backgroundForTag(_ tag: Int) -> FKIconViewBackgroundStyle {
    tag == 0 ? .none : .circle(fill: resolvedTint().withAlphaComponent(0.15))
  }
}

final class FKIconViewExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"

    let host = UIHostingController(rootView: FKIconViewSwiftUIDemoRoot())
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

final class FKIconViewExampleSwiftUIViewController: UIViewController {
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
