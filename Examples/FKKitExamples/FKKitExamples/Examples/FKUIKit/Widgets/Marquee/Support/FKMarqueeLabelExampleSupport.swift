import FKUIKit
import UIKit

/// Shared layout helpers for Marquee widget examples.
enum FKMarqueeLabelExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
    static let marqueeTrackHeight: CGFloat = 36
  }

  static let sampleShortText = "All systems operational"
  static let sampleLongText =
    "Limited-time offer — free express shipping on all orders over $50 through Sunday. Tap banner for full terms and regional eligibility."

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

  static func statusLabel(initial: String) -> UILabel {
    let label = UILabel()
    label.text = initial
    label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    return label
  }

  /// Fixed-width track so overflow text triggers scrolling.
  static func marqueeTrack(
    _ marquee: FKMarqueeLabel,
    backgroundColor: UIColor = .tertiarySystemFill
  ) -> UIView {
    marquee.translatesAutoresizingMaskIntoConstraints = false

    let track = UIView()
    track.translatesAutoresizingMaskIntoConstraints = false
    track.backgroundColor = backgroundColor
    track.layer.cornerRadius = 8
    track.layer.cornerCurve = .continuous
    track.clipsToBounds = true
    track.addSubview(marquee)

    NSLayoutConstraint.activate([
      track.heightAnchor.constraint(equalToConstant: Metrics.marqueeTrackHeight),
      marquee.leadingAnchor.constraint(equalTo: track.leadingAnchor, constant: 12),
      marquee.trailingAnchor.constraint(equalTo: track.trailingAnchor, constant: -12),
      marquee.centerYAnchor.constraint(equalTo: track.centerYAnchor),
    ])

    return track
  }

  static func announcementBar(marquee: FKMarqueeLabel) -> UIView {
    marquee.translatesAutoresizingMaskIntoConstraints = false

    let icon = UIImageView(image: UIImage(systemName: "megaphone.fill"))
    icon.tintColor = .systemOrange
    icon.setContentHuggingPriority(.required, for: .horizontal)
    icon.setContentCompressionResistancePriority(.required, for: .horizontal)

    let bar = UIStackView(arrangedSubviews: [icon, marquee])
    bar.axis = .horizontal
    bar.alignment = .center
    bar.spacing = 10
    bar.isLayoutMarginsRelativeArrangement = true
    bar.layoutMargins = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
    bar.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
    bar.layer.cornerRadius = 10
    bar.layer.cornerCurve = .continuous

    NSLayoutConstraint.activate([
      icon.widthAnchor.constraint(equalToConstant: 20),
      icon.heightAnchor.constraint(equalToConstant: 20),
    ])

    return bar
  }
}

@MainActor
class FKMarqueeLabelExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKMarqueeLabelExampleSupport.makeRootScrollStack()
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
    FKMarqueeLabelExampleSupport.pinScrollView(scrollView, in: view)
  }
}
