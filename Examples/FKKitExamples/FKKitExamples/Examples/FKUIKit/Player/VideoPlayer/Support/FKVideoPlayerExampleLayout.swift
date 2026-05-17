import UIKit

/// Shared layout helpers for VideoPlayer example screens.
enum FKVideoPlayerExampleLayout {

  static func makeSectionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    return label
  }

  static func makeCaptionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    return label
  }

  static func makeCardStack(arrangedSubviews: [UIView]) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
    stack.axis = .vertical
    stack.spacing = 12
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    stack.backgroundColor = .secondarySystemGroupedBackground
    stack.layer.cornerRadius = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }

  static func makePrimaryButton(_ title: String, action: UIAction) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .medium
    let button = UIButton(configuration: config, primaryAction: action)
    return button
  }

  static func pinPlayerContainer(_ container: UIView, in host: UIView, below anchor: NSLayoutYAxisAnchor) {
    container.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(container)
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: anchor, constant: 12),
      container.leadingAnchor.constraint(equalTo: host.layoutMarginsGuide.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: host.layoutMarginsGuide.trailingAnchor),
      container.heightAnchor.constraint(equalTo: host.heightAnchor, multiplier: 0.42),
    ])
  }
}
