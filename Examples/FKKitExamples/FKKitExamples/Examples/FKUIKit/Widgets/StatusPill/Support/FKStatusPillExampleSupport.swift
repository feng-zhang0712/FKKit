import FKUIKit
import UIKit

/// Shared layout helpers for StatusPill widget examples.
enum FKStatusPillExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
  }

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true
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

  static func pinScrollView(_ scrollView: UIScrollView, in host: UIView) {
    host.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
  }

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

  static func styleRow(label: String, pill: FKStatusPill) -> UIStackView {
    let name = UILabel()
    name.text = label
    name.font = .preferredFont(forTextStyle: .caption1)
    name.textColor = .secondaryLabel
    name.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    pill.translatesAutoresizingMaskIntoConstraints = false
    let row = UIStackView(arrangedSubviews: [name, pill])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    return row
  }

  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    control.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.required, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    return row
  }

  static func makePill(
    title: String,
    style: FKStatusPillStyle,
    showsDot: Bool = false,
    configuration: FKStatusPillConfiguration = FKStatusPillDefaults.configuration
  ) -> FKStatusPill {
    FKStatusPill(configuration: configuration, title: title, style: style, showsDot: showsDot)
  }
}

@MainActor
class FKStatusPillExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKStatusPillExampleSupport.makeRootScrollStack()
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
    view.backgroundColor = .systemGroupedBackground
    FKStatusPillExampleSupport.pinScrollView(scrollView, in: view)
  }
}
