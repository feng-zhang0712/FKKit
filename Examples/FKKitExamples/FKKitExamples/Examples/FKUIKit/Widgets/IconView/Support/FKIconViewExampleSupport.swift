import FKUIKit
import UIKit

/// Shared layout helpers for IconView widget examples.
enum FKIconViewExampleSupport {

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

  /// Horizontal label + control row. Inserts a flexible spacer by default so fixed-size controls (e.g. ``FKIconView``) stay at intrinsic width on the trailing edge.
  static func labeledRow(title: String, control: UIView, trailing: Bool = true) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    var arrangedSubviews: [UIView] = [titleLabel]
    if trailing {
      let spacer = UIView()
      spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
      spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      arrangedSubviews.append(spacer)
    }

    arrangedSubviews.append(control)

    let row = UIStackView(arrangedSubviews: arrangedSubviews)
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 16
    return row
  }

  static func sizeLabel(for size: FKIconViewSize) -> String {
    switch size {
    case .s: "S · 24pt"
    case .m: "M · 28pt"
    case .l: "L · 32pt"
    }
  }

  static func makeIcon(
    size: FKIconViewSize = .m,
    symbolName: String? = "star.fill",
    backgroundStyle: FKIconViewBackgroundStyle = .none,
    tintColor: UIColor? = nil
  ) -> FKIconView {
    var config = FKIconViewConfiguration()
    config.layout.size = size
    config.appearance.backgroundStyle = backgroundStyle
    if let tintColor {
      config.appearance.defaultTintColor = tintColor
    }
    let icon = FKIconView(configuration: config, symbolName: symbolName, tintColor: tintColor)
    return icon
  }

  /// Two-tone bitmap for demonstrating original (non-template) rendering.
  static func sampleColoredGlyphImage(side: CGFloat = 17) -> UIImage {
    let size = CGSize(width: side, height: side)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      UIColor.systemOrange.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: side * 0.55, height: side * 0.55))
      UIColor.systemTeal.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(x: side * 0.35, y: side * 0.35, width: side * 0.55, height: side * 0.55))
    }
  }

  static func settingsRow(title: String, icon: FKIconView, accessory: UIView? = nil) -> UIStackView {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 1

    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

    var views: [UIView] = [icon, titleLabel, spacer]
    if let accessory {
      views.append(accessory)
    } else {
      let chevron = UIImageView(image: UIImage(systemName: "chevron.forward"))
      chevron.tintColor = .tertiaryLabel
      chevron.setContentHuggingPriority(.required, for: .horizontal)
      views.append(chevron)
    }

    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12
    return row
  }

  /// Applies a forced layout direction across the scroll demo chrome and any extra demo views (e.g. settings rows, icons).
  static func applyLayoutDirection(
    _ attribute: UISemanticContentAttribute,
    in host: FKIconViewExampleScrollViewController,
    additionally views: [UIView] = []
  ) {
    host.view.semanticContentAttribute = attribute
    host.scrollView.semanticContentAttribute = attribute
    host.contentStack.semanticContentAttribute = attribute
    views.forEach {
      $0.semanticContentAttribute = attribute
      $0.setNeedsLayout()
    }
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
  }
}

@MainActor
class FKIconViewExampleScrollViewController: UIViewController {
  let scrollView: UIScrollView
  let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    let pair = FKIconViewExampleSupport.makeRootScrollStack()
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
    FKIconViewExampleSupport.pinScrollView(scrollView, in: view)
  }
}
