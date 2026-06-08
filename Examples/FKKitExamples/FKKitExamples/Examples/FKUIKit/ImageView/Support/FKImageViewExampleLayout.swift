import UIKit

/// Shared scroll + stack layout for ImageView / ImageLoader examples.
enum FKImageViewExampleLayout {
  @discardableResult
  static func installScrollableForm(in view: UIView, safeArea: UILayoutGuide) -> UIStackView {
    let scroll = UIScrollView()
    scroll.alwaysBounceVertical = true
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: safeArea.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
    ])
    return stack
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func sectionHeader(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func primaryButton(title: String, action: UIAction) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.addAction(action, for: .touchUpInside)
    return button
  }

  static func imageHost(height: CGFloat = 180) -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.heightAnchor.constraint(equalToConstant: height).isActive = true
    container.backgroundColor = .secondarySystemBackground
    container.layer.cornerCurve = .continuous
    container.layer.cornerRadius = 12
    container.clipsToBounds = true
    return container
  }

  static func embed(_ child: UIView, in container: UIView) {
    child.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(child)
    NSLayoutConstraint.activate([
      child.topAnchor.constraint(equalTo: container.topAnchor),
      child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  static func stateLabel() -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = "State: idle"
    return label
  }
}
