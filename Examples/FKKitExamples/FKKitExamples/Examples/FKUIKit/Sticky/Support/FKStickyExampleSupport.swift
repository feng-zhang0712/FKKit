import FKUIKit
import UIKit

/// Shared UI helpers for FKSticky demos.
enum FKStickyExampleUI {
  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func headline(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    return label
  }

  static func statusLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "Status: idle"
    return label
  }

  /// Colored sticky strip used as sticky content (not a product chrome component).
  static func makeStrip(
    title: String,
    backgroundColor: UIColor,
    height: CGFloat = 48
  ) -> FKStickyExampleStripView {
    let strip = FKStickyExampleStripView(title: title, backgroundColor: backgroundColor)
    strip.translatesAutoresizingMaskIntoConstraints = false
    strip.heightAnchor.constraint(equalToConstant: height).isActive = true
    strip.setContentHuggingPriority(.defaultLow, for: .horizontal)
    strip.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return strip
  }

  static func makeFillerBlock(index: Int, height: CGFloat = 72) -> UIView {
    let view = UIView()
    view.backgroundColor = index.isMultiple(of: 2) ? .secondarySystemBackground : .tertiarySystemBackground
    view.layer.cornerRadius = 10
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Content block \(index + 1)"
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    return view
  }

  static func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.bordered()
    config.title = title
    let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }
}

/// Simple titled bar used as sticky target content in demos.
final class FKStickyExampleStripView: UIView {
  let titleLabel = UILabel()

  /// Prevents UIStackView from sizing the strip to the title’s intrinsic (~half-screen) width.
  override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
  }

  init(title: String, backgroundColor: UIColor) {
    super.init(frame: .zero)
    self.backgroundColor = backgroundColor
    layer.cornerRadius = 8
    layer.masksToBounds = false

    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .white
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setStripHeight(_ height: CGFloat) {
    constraints.filter { $0.firstAttribute == .height && $0.firstItem as? UIView == self }.forEach {
      $0.constant = height
    }
    invalidateIntrinsicContentSize()
  }
}

/// Scroll page with a vertical content stack, status label, and optional toolbar actions.
class FKStickyExampleScrollPageViewController: UIViewController, UIScrollViewDelegate {
  let scrollView = UIScrollView()
  let contentStack = UIStackView()
  let statusLabel = FKStickyExampleUI.statusLabel()
  private let actionsStack = UIStackView()

  /// When `true`, this page becomes `scrollView.delegate` (needed for manual sticky forwarding demos).
  var becomesScrollViewDelegate: Bool { false }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    // Scroll view is already pinned under the safe area; keep inset adjustment off so the
    // sticky pin line is not shifted by a second copy of the nav-bar inset.
    scrollView.contentInsetAdjustmentBehavior = .never
    // Reserve space for the fixed status footer so the last content rows stay reachable.
    scrollView.contentInset.bottom = 40
    scrollView.verticalScrollIndicatorInsets.bottom = 40
    if becomesScrollViewDelegate {
      scrollView.delegate = self
    }
    view.addSubview(scrollView)

    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = 12
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    // Status lives outside the scroll content so progress callbacks cannot mutate contentSize
    // while the user is at max offset (that fight can cancel the pan / feel "stuck" at the bottom).
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)

    actionsStack.axis = .vertical
    actionsStack.spacing = 8
    actionsStack.isLayoutMarginsRelativeArrangement = true
    actionsStack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),

      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])
  }

  func addIntro(title: String, body: String) {
    contentStack.addArrangedSubview(FKStickyExampleUI.headline(title))
    contentStack.addArrangedSubview(FKStickyExampleUI.caption(body))
  }

  /// Adds a sticky strip and pins its width to the content stack (full content width).
  func addStickyStrip(_ strip: UIView) {
    strip.translatesAutoresizingMaskIntoConstraints = false
    strip.setContentHuggingPriority(.defaultLow, for: .horizontal)
    strip.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    contentStack.addArrangedSubview(strip)
    let width = strip.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
    width.priority = .required
    width.isActive = true
  }

  func addActions(_ buttons: [UIButton]) {
    actionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    buttons.forEach { actionsStack.addArrangedSubview($0) }
    if actionsStack.superview == nil {
      contentStack.addArrangedSubview(actionsStack)
    }
  }

  func addFillerBlocks(count: Int = 18) {
    for index in 0..<count {
      contentStack.addArrangedSubview(FKStickyExampleUI.makeFillerBlock(index: index))
    }
  }

  func updateStatus(_ text: String) {
    statusLabel.text = text
  }

  func progressLine(for engine: FKStickyEngine, id: String) -> String {
    guard let progress = engine.progress(for: id) else { return "\(id): —" }
    return "\(id): \(progress.state.rawValue) p=\(String(format: "%.2f", progress.value))"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure first sticky metrics are taken after Auto Layout assigns stack widths.
    view.layoutIfNeeded()
    scrollView.fk_reloadStickyLayout()
  }
}
