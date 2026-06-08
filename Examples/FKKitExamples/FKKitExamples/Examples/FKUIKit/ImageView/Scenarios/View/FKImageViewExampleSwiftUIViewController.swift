import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKImageViewSwiftUIDemoRoot: View {
  @State private var url: URL? = FKImageViewExampleURLs.photo(id: 5)
  @State private var stateText = "idle"
  @State private var cornerRadius: CGFloat = 12

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKImageViewRepresentable(
            url: url,
            configuration: {
              var config = FKImageViewConfiguration()
              config.appearance.cornerStyle = .fixed(cornerRadius)
              config.loading.placeholder = .symbol(name: "photo", pointSize: 28, weight: .regular)
              return config
            }(),
            onStateChange: { state in
              stateText = FKImageViewExampleFormatting.describe(state)
            },
            onTap: {}
          )
          .frame(height: 220)
        } header: {
          Text("FKImageViewRepresentable")
        } footer: {
          Text("State: \(stateText)")
        }

        Section("Controls") {
          Slider(value: $cornerRadius, in: 0...32, step: 1) {
            Text("Corner radius")
          }
          Button("Load photo #21") {
            url = FKImageViewExampleURLs.photo(id: 21)
          }
          Button("Clear URL") {
            url = nil
          }
        }
      }
      .navigationTitle("SwiftUI")
    }
    .navigationViewStyle(.stack)
  }
}
#endif

final class FKImageViewExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
#if canImport(SwiftUI)
    title = "SwiftUI"
    let host = UIHostingController(rootView: FKImageViewSwiftUIDemoRoot())
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
    label.text = "SwiftUI is not available in this build."
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
#endif
  }
}
