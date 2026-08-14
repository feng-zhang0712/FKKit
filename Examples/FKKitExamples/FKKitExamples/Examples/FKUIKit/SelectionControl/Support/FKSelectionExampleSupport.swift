import FKUIKit
import UIKit

/// Shared layout chrome for ``FKCheckbox`` / ``FKRadioButton`` / ``FKRadioGroup`` examples.
enum FKSelectionExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    static let cardContentSpacing: CGFloat = 12
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

  static func statusLabel(prefix: String = "Status") -> (UILabel, (String) -> Void) {
    let label = UILabel()
    label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = "\(prefix): —"
    let update: (String) -> Void = { value in
      label.text = "\(prefix): \(value)"
    }
    return (label, update)
  }

  static func embedControl(_ control: UIView) -> UIView {
    control.translatesAutoresizingMaskIntoConstraints = false
    let host = UIStackView(arrangedSubviews: [control])
    host.axis = .vertical
    host.alignment = .fill
    return host
  }

  static func makeButton(title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.bordered()
    config.title = title
    let button = UIButton(configuration: config)
    button.addAction(UIAction { _ in action() }, for: .primaryActionTriggered)
    return button
  }

  static func billingOptions() -> [FKRadioOption] {
    [
      FKRadioOption(id: "week", title: "Weekly", subtitle: "Billed every 7 days"),
      FKRadioOption(id: "month", title: "Monthly", subtitle: "Best value for most teams"),
      FKRadioOption(id: "year", title: "Yearly", subtitle: "Two months free"),
    ]
  }

  static func paymentOptionsWithImages() -> [FKRadioOption] {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
    return [
      FKRadioOption(
        id: "card",
        title: "Credit card",
        subtitle: "Visa, Mastercard, Amex",
        image: UIImage(systemName: "creditcard", withConfiguration: config)
      ),
      FKRadioOption(
        id: "wallet",
        title: "Digital wallet",
        subtitle: "Apple Pay and more",
        image: UIImage(systemName: "wallet.pass", withConfiguration: config)
      ),
      FKRadioOption(
        id: "bank",
        title: "Bank transfer",
        subtitle: "1–3 business days",
        image: UIImage(systemName: "building.columns", withConfiguration: config)
      ),
    ]
  }
}

@MainActor
class FKSelectionExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKSelectionExampleSupport.makeRootScrollStack()
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
    FKSelectionExampleSupport.pinScrollView(scrollView, in: view)
  }
}
