import FKUIKit
import UIKit

/// Shared layout helpers and demo fixtures for Avatar widget examples.
enum FKAvatarExampleSupport {

  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 32, trailing: 20)
    static let cardSpacing: CGFloat = 24
    static let cardPadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    static let cardContentSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 12
  }

  static func avatarURL(id: Int, size: Int = 160) -> URL {
    URL(string: "https://picsum.photos/id/\(id)/\(size)/\(size)")!
  }

  static var brokenURL: URL {
    URL(string: "https://httpbin.org/status/404")!
  }

  static func feedPersonIDs(count: Int) -> [Int] {
    (0 ..< count).map { 60 + ($0 * 11) % 30 }
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

  static func eventLogLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    label.text = "Events will appear here."
    return label
  }

  static func horizontalRow(spacing: CGFloat = Metrics.rowSpacing, alignment: UIStackView.Alignment = .center) -> UIStackView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = spacing
    row.alignment = alignment
    row.distribution = .fill
    return row
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

  static func embedAvatar(_ avatar: FKAvatar, alignment: UIStackView.Alignment = .center) -> UIView {
    avatar.translatesAutoresizingMaskIntoConstraints = false
    let row = UIStackView(arrangedSubviews: [avatar])
    row.axis = .vertical
    row.alignment = alignment
    return row
  }

  static func embedGroup(_ group: FKAvatarGroup) -> UIView {
    group.translatesAutoresizingMaskIntoConstraints = false
    let row = UIStackView(arrangedSubviews: [group])
    row.axis = .vertical
    row.alignment = .leading
    return row
  }

  static func makeLocalAvatarImage(label: String, color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 160))
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 160, height: 160))
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 28),
        .foregroundColor: UIColor.white,
      ]
      let size = (label as NSString).size(withAttributes: attrs)
      let origin = CGPoint(x: (160 - size.width) / 2, y: (160 - size.height) / 2)
      (label as NSString).draw(at: origin, withAttributes: attrs)
    }
  }

  static func sampleGroupMembers() -> [FKAvatarContent] {
    [
      FKAvatarContent(id: "1", displayName: "Alex Morgan", imageURL: avatarURL(id: 64)),
      FKAvatarContent(id: "2", displayName: "Sam Chen", imageURL: avatarURL(id: 65)),
      FKAvatarContent(id: "3", displayName: "Jordan Lee", imageURL: avatarURL(id: 66)),
      FKAvatarContent(id: "4", displayName: "Casey Kim", imageURL: avatarURL(id: 67)),
      FKAvatarContent(id: "5", displayName: "Riley Park", imageURL: avatarURL(id: 68)),
      FKAvatarContent(id: "6", displayName: "Taylor Wu", imageURL: avatarURL(id: 69)),
      FKAvatarContent(id: "7", displayName: "Jamie Fox", imageURL: avatarURL(id: 70)),
    ]
  }
}

@MainActor
class FKAvatarExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKAvatarExampleSupport.makeRootScrollStack()
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
    FKAvatarExampleSupport.pinScrollView(scrollView, in: view)
  }
}
