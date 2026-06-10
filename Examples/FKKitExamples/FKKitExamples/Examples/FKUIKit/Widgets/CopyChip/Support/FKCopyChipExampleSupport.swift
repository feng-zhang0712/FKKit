import FKUIKit
import UIKit

/// Shared layout helpers for CopyChip widget examples.
enum FKCopyChipExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
  }

  static let sampleOrderID = "A128839F2E7B4C1D"
  static let sampleTrackingNumber = "1Z999AA10123456784"

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

  static func eventLogLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = "Tap a chip — events and pasteboard contents appear here."
    return label
  }

  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [titleLabel, control])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    return row
  }

  static func embedChip(_ chip: FKCopyChip) -> UIView {
    chip.translatesAutoresizingMaskIntoConstraints = false
    return chip
  }

  static func pasteboardPreview() -> String {
    UIPasteboard.general.string ?? "(empty)"
  }
}

@MainActor
class FKCopyChipExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKCopyChipExampleSupport.makeRootScrollStack()
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
    FKCopyChipExampleSupport.pinScrollView(scrollView, in: view)
  }
}
