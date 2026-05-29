import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKRatingSwiftUIDemoRoot: View {
  @State private var value: Double = 2.5
  @State private var configuration: FKRatingConfiguration = {
    var config = FKRatingDefaults.configuration
    config.interaction.mode = .interactive
    config.interaction.step = .half
    config.layout.labelPlacement = .trailing
    config.appearance.filledColor = .systemYellow
  return config
  }()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKRatingControlRepresentable(
            value: $value,
            configuration: configuration,
            animateChanges: true
          ) { newValue in
            // Demonstrates optional side-effect hook from the bridge.
            _ = newValue
          }
          .frame(minHeight: 44)
        } header: {
          Text("Live control")
        } footer: {
          Text("FKRatingControlRepresentable mirrors the binding into UIKit and forwards user changes back to SwiftUI.")
        }

        Section("Value") {
          Slider(value: $value, in: 0...5, step: 0.5)
          Text(String(format: "Binding: %.1f", value))
            .font(.body.monospacedDigit())
        }

        Section("Appearance") {
          Picker("Mode", selection: Binding(
            get: { configuration.interaction.mode == .interactive ? 0 : 1 },
            set: { tag in
              var copy = configuration
              copy.interaction.mode = tag == 0 ? .interactive : .readOnly
              configuration = copy
            }
          )) {
            Text("Interactive").tag(0)
            Text("Read-only").tag(1)
          }
          .pickerStyle(.segmented)

          Picker("Icon", selection: Binding(
            get: {
              switch configuration.appearance.iconStyle {
              case .preset(.heart): return 1
              case .preset(.thumbUp): return 2
              default: return 0
              }
            },
            set: { tag in
              var copy = configuration
              copy.appearance.iconStyle = .preset({
                switch tag {
                case 1: return .heart
                case 2: return .thumbUp
                default: return .star
                }
              }())
              configuration = copy
            }
          )) {
            Text("Star").tag(0)
            Text("Heart").tag(1)
            Text("Thumb").tag(2)
          }
          .pickerStyle(.segmented)
        }
      }
      .navigationTitle("SwiftUI")
    }
    .navigationViewStyle(.stack)
  }
}
#endif

/// Hosts the SwiftUI bridge demo when SwiftUI is available.
final class FKRatingExampleSwiftUIViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    title = "SwiftUI bridge"
    let host = UIHostingController(rootView: FKRatingSwiftUIDemoRoot())
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
    title = "SwiftUI"
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.text = "SwiftUI is not available in this build."
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
    ])
#endif
  }
}
