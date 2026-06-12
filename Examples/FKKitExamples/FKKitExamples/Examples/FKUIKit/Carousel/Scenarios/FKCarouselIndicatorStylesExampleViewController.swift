import FKUIKit
import UIKit

/// Cycles indicator styles, placements, and custom renderer.
final class FKCarouselIndicatorStylesExampleViewController: FKCarouselExampleScrollViewController {
  private let carousel = FKCarousel()
  private let styleControl = UISegmentedControl(items: ["Dots", "Bar", "Fraction", "Line", "Custom", "None"])
  private let placementControl = UISegmentedControl(items: ["Overlay↓", "Overlay↑", "Below", "Above"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator styles"
    installScrollRootChrome()

    carousel.setItems(FKCarouselExampleSupport.onboardingItems())
    carousel.pageProvider = { item, bounds in
      FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
    }
    carousel.customIndicatorRenderer = { container, pageCount, progress in
      container.subviews.forEach { $0.removeFromSuperview() }
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .caption1)
      label.textColor = .white
      label.textAlignment = .center
      label.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.85)
      label.layer.cornerRadius = 10
      label.clipsToBounds = true
      label.text = String(format: "Custom %.0f%% · %d pages", progress * 100, pageCount)
      label.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(label)
      NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        label.heightAnchor.constraint(equalToConstant: 28),
      ])
    }

    styleControl.selectedSegmentIndex = 0
    placementControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] _ in self?.applyStyle() }, for: .valueChanged)
    placementControl.addAction(UIAction { [weak self] _ in self?.applyStyle() }, for: .valueChanged)

    contentStack.addArrangedSubview(styleControl)
    contentStack.addArrangedSubview(placementControl)
    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Demonstrates FKCarouselIndicatorStyle and FKCarouselIndicatorPlacement. Custom style uses carousel.customIndicatorRenderer."
    ))

    applyStyle()
  }

  private func applyStyle() {
    var config = carousel.configuration
    switch styleControl.selectedSegmentIndex {
    case 0: config.indicator.style = .dots
    case 1: config.indicator.style = .bar
    case 2: config.indicator.style = .fraction
    case 3: config.indicator.style = .line
    case 4: config.indicator.style = .custom(id: "demo")
    default: config.indicator.style = .none
    }

    switch placementControl.selectedSegmentIndex {
    case 1: config.indicator.placement = .overlayTop(inset: 12)
    case 2: config.indicator.placement = .below(spacing: 8)
    case 3: config.indicator.placement = .above(spacing: 8)
    default: config.indicator.placement = .overlayBottom(inset: 12)
    }

    config.indicator.indicatorFollowsScrollProgress = true
    carousel.apply(configuration: config)
  }
}
