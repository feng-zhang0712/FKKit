import FKUIKit
import UIKit
#if canImport(SwiftUI)
import SwiftUI

private struct FKThemeSwiftUIDemoRoot: View {
  @State private var theme = FKThemeRegistry.current

  var body: some View {
    NavigationView {
      Form {
        Section {
          HStack(spacing: 12) {
            Circle()
              .fill(Color(theme.colors.primary.resolved(for: UITraitCollection.current)))
              .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
              Text("Primary token")
                .font(.headline)
              Text(theme.id)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        } header: {
          Text("Environment theme")
        } footer: {
          Text("SwiftUI reads EnvironmentValues.fkTheme without writing back to FKThemeRegistry.")
        }

        Section("Typography") {
          Text("Headline sample")
            .font(Font(theme.typography.font(for: .headline) as UIFont))
          Text("Body sample")
            .font(Font(theme.typography.font(for: .body) as UIFont))
        }

        Section("Actions") {
          Button("Apply teal brand to environment") {
            var brand = FKTheme.default
            brand.id = "swiftui.brand"
            brand.colors.primary = FKThemeColor(fixed: .systemTeal)
            theme = brand
          }
          Button("Reset environment to default") {
            theme = .default
          }
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
    .fkTheme(theme)
  }
}

/// Hosts FKTheme SwiftUI environment injection.
final class FKThemeExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemBackground

    let host = UIHostingController(rootView: FKThemeSwiftUIDemoRoot())
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
#else
final class FKThemeExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    let label = UILabel()
    label.text = "SwiftUI is unavailable in this build configuration."
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
    ])
  }
}
#endif
