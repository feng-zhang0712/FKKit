import FKUIKit
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKMediaGalleryExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground

    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKMediaGallerySwiftUIExampleSurface())
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
private struct FKMediaGallerySwiftUIExampleSurface: View {
  @State private var isPresented = false
  private let items = FKMediaGalleryExampleCatalog.productDetailItems()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Use FKMediaGalleryPresenter or the fkMediaGallery view modifier to drive presentation from SwiftUI state.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Button("Present gallery") {
          isPresented = true
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, minHeight: 44)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
    .fkMediaGallery(
      isPresented: $isPresented,
      items: items,
      startIndex: 0,
      configuration: FKMediaGalleryPresets.productDetail()
    )
  }
}
#endif
