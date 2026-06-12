import FKCoreKit
import FKUIKit
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKQRCodeScannerExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground

    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKQRCodeSwiftUIExampleSurface())
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
private struct FKQRCodeSwiftUIExampleSurface: View {
  @State private var lastScanMessage = "No scan yet."
  @State private var showScanner = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("FKQRCodeImageView generates a QR bitmap off the main actor. FKQRCodeScannerRepresentable embeds the UIKit scanner.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
          Text("Generated QR")
            .font(.headline)
          FKQRCodeImageView(
            content: "https://example.com/swiftui",
            options: {
              var options = FKQRCodeGenerationOptions.default
              options.size = CGSize(width: 200, height: 200)
              options.foregroundColor = .label
              options.backgroundColor = .systemBackground
              return options
            }()
          )
          .frame(maxWidth: 220)
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Scanner")
            .font(.headline)
          Text(lastScanMessage)
            .font(.footnote.monospaced())
            .foregroundStyle(.secondary)
          Button("Present FKQRCodeScannerRepresentable") {
            showScanner = true
          }
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
    }
    .fullScreenCover(isPresented: $showScanner) {
      FKQRCodeScannerRepresentable(
        configuration: {
          var config = FKQRCodeScannerConfiguration.default
          config.simulatorMockRawValue = "https://example.com/swiftui-scan"
          return config
        }(),
        onScan: { payload in
          lastScanMessage = FKQRCodeExampleFormatting.describe(payload)
          showScanner = false
        },
        onCancel: {
          lastScanMessage = "cancelled"
          showScanner = false
        },
        onError: { error in
          lastScanMessage = FKQRCodeScannerExampleFormatting.describe(error)
        }
      )
      .ignoresSafeArea()
    }
  }
}
#endif
