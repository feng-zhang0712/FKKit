import FKUIKit
import UIKit

/// FKCarouselDataSource with reusable colored pages.
final class FKCarouselDataSourceExampleViewController: FKCarouselExampleScrollViewController, FKCarouselDataSource {
  private let carousel = FKCarousel()

  private let palette: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple]
  private var items: [FKCarouselItem] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Data source"
    installScrollRootChrome()

    items = (0 ..< 4).map { index in
      FKCarouselItem(
        id: "page-\(index)",
        accessibilityLabel: "Data source page \(index + 1)",
        isInteractive: index != 2
      )
    }

    var config = FKCarouselConfiguration()
    config.layout.heightStrategy = .aspectRatio(4.0 / 3.0)
    config.indicator.style = .dots
    config.indicator.placement = .below(spacing: 8)
    carousel.configuration = config
    carousel.dataSource = self
    carousel.setItems(items)

    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "FKCarouselDataSource supplies reused UIView instances. Page index 3 uses isInteractive = false (dimmed, no selection callback)."
    ))
  }

  func numberOfPages(in carousel: FKCarousel) -> Int {
    items.count
  }

  func carousel(_ carousel: FKCarousel, viewForPageAt index: Int, reusing view: UIView?) -> UIView {
    let page = (view as? DemoPageView) ?? DemoPageView()
    page.configure(
      title: items[index].accessibilityLabel ?? "Page",
      color: palette[index % palette.count]
    )
    return page
  }
}

private final class DemoPageView: UIView {
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.cornerRadius = 12
    label.font = .preferredFont(forTextStyle: .title2)
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func configure(title: String, color: UIColor) {
    backgroundColor = color
    label.text = title
  }
}
