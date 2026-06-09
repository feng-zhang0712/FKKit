import FKUIKit
import UIKit

/// Live toggles for auto-scroll, infinite loop, and direction.
final class FKCarouselAutoScrollExampleViewController: FKCarouselExampleScrollViewController {
  private let banner = FKImageBanner()
  private let autoScrollSwitch = UISwitch()
  private let loopSwitch = UISwitch()
  private let reverseSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Auto-scroll"
    installScrollRootChrome()

    var config = FKImageBannerPresets.homeHero()
    config.carousel.autoScroll.interval = 2.5
    banner.configuration = config
    banner.setSlides(FKCarouselExampleSlides.heroSlides(count: 4))

    autoScrollSwitch.isOn = true
    loopSwitch.isOn = true
    reverseSwitch.isOn = false

    autoScrollSwitch.addAction(UIAction { [weak self] _ in self?.applyToggles() }, for: .valueChanged)
    loopSwitch.addAction(UIAction { [weak self] _ in self?.applyToggles() }, for: .valueChanged)
    reverseSwitch.addAction(UIAction { [weak self] _ in self?.applyToggles() }, for: .valueChanged)

    contentStack.addArrangedSubview(makeToggleRow(title: "Auto-scroll enabled", toggle: autoScrollSwitch))
    contentStack.addArrangedSubview(makeToggleRow(title: "Infinite loop", toggle: loopSwitch))
    contentStack.addArrangedSubview(makeToggleRow(title: "Reverse direction", toggle: reverseSwitch))
    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Auto-scroll pauses on touch, when off-screen, and when UIAccessibility.isReduceMotionEnabled (if respectsReducedMotion). Drag the banner to verify pause/resume."
    ))
  }

  private func applyToggles() {
    var config = banner.configuration
    config.carousel.autoScroll.isEnabled = autoScrollSwitch.isOn
    config.carousel.autoScroll.direction = reverseSwitch.isOn ? .reverse : .forward
    config.carousel.layout.isInfiniteLoopEnabled = loopSwitch.isOn
    banner.apply(configuration: config)
    banner.setSlides(banner.slides, preservingIndex: true)
  }

  private func makeToggleRow(title: String, toggle: UISwitch) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .body)
    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }
}
