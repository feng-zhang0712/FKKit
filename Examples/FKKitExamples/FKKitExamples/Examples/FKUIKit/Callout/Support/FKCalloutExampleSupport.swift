import UIKit
import FKUIKit

enum FKCalloutExampleUI {
  static func makeScrollContent(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 14
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    viewController.view.addSubview(scroll)

    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
      stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
    ])
    return stack
  }

  static func section(title: String, description: String, body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.text = title

    let descriptionLabel = UILabel()
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = description

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(descriptionLabel)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func row(_ views: [UIView]) -> UIStackView {
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    return row
  }

  static func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 10
    button.heightAnchor.constraint(equalToConstant: 42).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }

  /// Prominent tap target used as callout anchors in demos.
  static func anchorButton(_ title: String) -> UIButton {
    let button = UIButton(type: .system)
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    config.baseBackgroundColor = .systemIndigo
    config.baseForegroundColor = .white
    button.configuration = config
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return button
  }

  static func anchorCanvas(anchor: UIView, height: CGFloat = 220) -> UIView {
    let canvas = UIView()
    canvas.backgroundColor = .tertiarySystemGroupedBackground
    canvas.layer.cornerRadius = 12
    canvas.translatesAutoresizingMaskIntoConstraints = false
    canvas.heightAnchor.constraint(equalToConstant: height).isActive = true

    anchor.translatesAutoresizingMaskIntoConstraints = false
    canvas.addSubview(anchor)
    NSLayoutConstraint.activate([
      anchor.centerXAnchor.constraint(equalTo: canvas.centerXAnchor),
      anchor.centerYAnchor.constraint(equalTo: canvas.centerYAnchor),
      anchor.leadingAnchor.constraint(greaterThanOrEqualTo: canvas.leadingAnchor, constant: 16),
      anchor.trailingAnchor.constraint(lessThanOrEqualTo: canvas.trailingAnchor, constant: -16),
    ])
    return canvas
  }

  static func statusLabel() -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "Tap a control to present a callout."
    return label
  }
}

class FKCalloutExampleBaseViewController: UIViewController {
  var contentStack: UIStackView!
  let statusLabel = FKCalloutExampleUI.statusLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    contentStack = FKCalloutExampleUI.makeScrollContent(in: self)
    contentStack.addArrangedSubview(statusLabel)
  }

  func log(_ text: String) {
    statusLabel.text = text
  }
}
