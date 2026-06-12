import FKUIKit
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKPhotoPickerExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground

    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKPhotoPickerSwiftUIExampleSurface())
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
private struct FKPhotoPickerSwiftUIExampleSurface: View {
  @State private var statusMessage = "Tap a button to pick media."

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("FKPhotoPickerButton resolves the nearest UIViewController presenter and calls the same async coordinator as UIKit.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(statusMessage)
          .font(.footnote)
          .foregroundStyle(.secondary)

        FKPhotoPickerButton(configuration: .avatar()) { result in
          switch result {
          case let .success(items):
            statusMessage = "Avatar pick succeeded · \(items.count) item(s)"
            FKPhotoPickerExampleLog.shared.append("SwiftUI avatar: \(items.count) result(s)")
          case let .failure(error):
            statusMessage = FKPhotoPickerExampleFormatting.describe(error)
            FKPhotoPickerExampleLog.shared.append("SwiftUI avatar error: \(FKPhotoPickerExampleFormatting.describe(error))")
          }
        } label: {
          Text("Pick avatar (preset)")
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)

        FKPhotoPickerButton(configuration: .chatAttachments(max: 4)) { result in
          switch result {
          case let .success(items):
            statusMessage = "Multi pick · \(items.count) item(s)"
            FKPhotoPickerExampleLog.shared.append("SwiftUI multi: \(items.count) result(s)")
          case let .failure(error):
            statusMessage = FKPhotoPickerExampleFormatting.describe(error)
          }
        } label: {
          Text("Pick up to 4 images")
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)

        FKPhotoPickerButton(configuration: .init(source: .libraryOrCamera)) { result in
          switch result {
          case let .success(items):
            statusMessage = "Source chooser · \(items.count) item(s)"
          case let .failure(error):
            statusMessage = FKPhotoPickerExampleFormatting.describe(error)
          }
        } label: {
          Text("Library or camera chooser")
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
