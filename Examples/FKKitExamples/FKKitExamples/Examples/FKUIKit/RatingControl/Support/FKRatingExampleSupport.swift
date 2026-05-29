import UIKit
import FKUIKit

/// Shared layout and chrome for ``FKRatingControl`` examples.
enum FKRatingExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
    static let controlRowSpacing: CGFloat = 10
    static let ratingVerticalPadding: CGFloat = 12
  }

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true
    scroll.keyboardDismissMode = .onDrag
    scroll.contentInsetAdjustmentBehavior = .always

    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = Metrics.cardSpacing
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = Metrics.screenMargins
    scroll.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
    ])

    return (scroll, stack)
  }

  static func pinScrollView(_ scrollView: UIScrollView, contentStack: UIStackView, in host: UIView) {
    host.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
  }

  /// Padded card; add captions, controls, and ratings directly to the returned stack.
  static func sectionContainer(title: String) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel])
    stack.axis = .vertical
    stack.spacing = Metrics.cardContentSpacing
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = Metrics.cardPadding
    stack.backgroundColor = .secondarySystemGroupedBackground
    stack.layer.cornerRadius = 14
    stack.layer.cornerCurve = .continuous
    stack.clipsToBounds = true
    return stack
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func valueReadout(title: String = "Current value") -> (UILabel, (Double) -> Void) {
    let label = UILabel()
    label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = "\(title): 0"

    let update: (Double) -> Void = { value in
      label.text = String(format: "\(title): %.1f", value)
    }
    return (label, update)
  }

  /// Title above control — avoids squeezing segmented controls on narrow screens.
  static func controlRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0

    control.setContentHuggingPriority(.defaultLow, for: .horizontal)
    control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.axis = .vertical
    row.alignment = .fill
    row.spacing = Metrics.controlRowSpacing
    return row
  }

  /// Horizontal row for short controls (switches).
  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    row.distribution = .fill
    return row
  }

  static func centeredContainer(for content: UIView) -> UIView {
    let wrapper = UIView()
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    content.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: wrapper.topAnchor),
      content.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
      content.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
      content.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor),
      content.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor),
    ])
    return wrapper
  }

  static func embedRating(_ rating: FKRatingControl, alignment: UIStackView.Alignment = .leading) -> UIView {
    rating.translatesAutoresizingMaskIntoConstraints = false
    rating.setContentHuggingPriority(.required, for: .vertical)
    rating.setContentCompressionResistancePriority(.required, for: .vertical)

    let inner: UIView
    if alignment == .center {
      inner = centeredContainer(for: rating)
    } else {
      let host = UIStackView(arrangedSubviews: [rating])
      host.axis = .vertical
      host.alignment = alignment
      inner = host
    }

    inner.translatesAutoresizingMaskIntoConstraints = false
    let wrapper = UIView()
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(inner)
    NSLayoutConstraint.activate([
      inner.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: Metrics.ratingVerticalPadding),
      inner.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
      inner.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
      inner.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -Metrics.ratingVerticalPadding),
    ])
    return wrapper
  }

  static func symbolImage(named: String, pointSize: CGFloat = 22) -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    return UIImage(systemName: named, withConfiguration: config)
  }
}

@MainActor
class FKRatingExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKRatingExampleSupport.makeRootScrollStack()
    scrollView = pair.0
    contentStack = pair.1
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    installScrollRootChrome()
  }

  func installScrollRootChrome() {
    view.backgroundColor = .systemGroupedBackground
    FKRatingExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)
  }
}
