import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKCarouselSwiftUIDemoRoot: View {
  @State private var bannerPage = 0
  @State private var carouselPage = 0

  private let bannerSlides = FKCarouselExampleSlides.promoSlides(count: 4)
  private let carouselItems = FKCarouselExampleSupport.onboardingItems()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKImageBannerRepresentable(
            slides: bannerSlides,
            currentPage: $bannerPage,
            configuration: FKImageBannerPresets.compactPromo(),
            callbacks: .init(onSlideChanged: { index, _ in
              bannerPage = index
            })
          )
          .frame(height: 200)
        } header: {
          Text("FKImageBannerRepresentable")
        } footer: {
          Text("Bound page: \(bannerPage + 1) of \(bannerSlides.count)")
        }

        Section {
          FKCarouselRepresentable(
            items: carouselItems,
            currentPage: $carouselPage,
            configuration: FKCarouselPresets.onboarding(),
            pageProvider: { item, bounds in
              FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
            }
          )
          .frame(height: 220)
        } header: {
          Text("FKCarouselRepresentable")
        } footer: {
          Text("Bound page: \(carouselPage + 1) of \(carouselItems.count)")
        }
      }
      .navigationTitle("SwiftUI bridge")
    }
    .navigationViewStyle(.stack)
  }
}
#endif

final class FKCarouselSwiftUIExampleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

#if canImport(SwiftUI)
    title = "SwiftUI bridge"
    let host = UIHostingController(rootView: FKCarouselSwiftUIDemoRoot())
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
    title = "SwiftUI bridge"
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
