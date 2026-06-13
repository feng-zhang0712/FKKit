import FKUIKit
import UIKit

// MARK: - Shared chrome

enum FKThemeExampleSupport {

  static func makeScrollStack(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
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

  static func card(title: String, description: String, content: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 10
    wrap.backgroundColor = .secondarySystemGroupedBackground
    wrap.layer.cornerRadius = 12
    wrap.isLayoutMarginsRelativeArrangement = true
    wrap.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0

    let detailLabel = UILabel()
    detailLabel.text = description
    detailLabel.textColor = .secondaryLabel
    detailLabel.numberOfLines = 0
    detailLabel.font = .preferredFont(forTextStyle: .footnote)

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(detailLabel)
    wrap.addArrangedSubview(content)
    return wrap
  }

  static func bodyLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .secondaryLabel
    return label
  }

  static func colorSwatch(name: String, color: UIColor) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.alignment = .center

    let chip = UIView()
    chip.backgroundColor = color
    chip.layer.cornerRadius = 8
    chip.layer.borderWidth = 1 / UIScreen.main.scale
    chip.layer.borderColor = UIColor.separator.cgColor
    chip.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      chip.widthAnchor.constraint(equalToConstant: 44),
      chip.heightAnchor.constraint(equalToConstant: 44),
    ])

    let label = UILabel()
    label.text = name
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.numberOfLines = 0

    row.addArrangedSubview(chip)
    row.addArrangedSubview(label)
    return row
  }

  static func makeBrandTheme(primary: UIColor = .systemTeal) -> FKTheme {
    var theme = FKTheme.default
    theme.id = "examples.brand"
    theme.colors.primary = FKThemeColor(fixed: primary)
    theme.colors.onPrimary = FKThemeColor(fixed: .white)
    theme.colors.secondary = FKThemeColor(
      light: primary.withAlphaComponent(0.12),
      dark: primary.withAlphaComponent(0.22)
    )
    return theme
  }

  static func makeThemedButton(title: String, role: FKThemeButtonRole, theme: FKTheme) -> FKButton {
    let button = FKButton()
    button.content = .init(kind: .textOnly)
    button.setAppearances(theme.makeButtonStateAppearances(for: role))
    let color = theme.buttonTitleColor(for: role)
    [UIControl.State.normal, .highlighted, .selected, .disabled].forEach { state in
      button.setTitle(.init(text: title, font: .preferredFont(forTextStyle: .headline), color: color), for: state)
    }
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return button
  }

  static func applyLayerShadow(_ style: FKLayerShadowStyle, to layer: CALayer, path: CGPath? = nil) {
    switch style {
    case .none:
      layer.shadowColor = nil
      layer.shadowOpacity = 0
      layer.shadowRadius = 0
      layer.shadowOffset = .zero
      layer.shadowPath = nil
    case .custom(let color, let opacity, let radius, let offset):
      layer.shadowColor = color.cgColor
      layer.shadowOpacity = opacity
      layer.shadowRadius = radius
      layer.shadowOffset = offset
      layer.shadowPath = path
    }
  }

  static func restoreDefaultTheme() {
    FKThemeRegistry.register(FKTheme.default)
  }
}

class FKThemeExampleBaseViewController: UIViewController {
  var stack: UIStackView!
  /// When `true`, resets ``FKThemeRegistry`` to ``FKTheme/default`` when popping this screen.
  var restoresThemeOnExit = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    stack = FKThemeExampleSupport.makeScrollStack(in: self)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if restoresThemeOnExit, isMovingFromParent {
      FKThemeExampleSupport.restoreDefaultTheme()
    }
  }
}

/// Demo view that refreshes when ``FKThemeRegistry/themeDidChangeNotification`` fires.
final class FKThemeAwareBannerView: UIView, FKThemeAware {
  private let titleLabel = UILabel()
  private let valueLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.cornerRadius = 12
    let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
    stack.axis = .vertical
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
    ])
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    valueLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.text = "FKThemeAware"
    apply(theme: FKThemeRegistry.current)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(themeDidChange),
      name: FKThemeRegistry.themeDidChangeNotification,
      object: nil
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func apply(theme: FKTheme) {
    backgroundColor = theme.colors.primary.resolved(for: traitCollection)
    titleLabel.textColor = theme.colors.onPrimary.resolved(for: traitCollection)
    valueLabel.textColor = theme.colors.onPrimary.resolved(for: traitCollection)
    valueLabel.text = "Active theme id: \(theme.id)"
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    apply(theme: FKThemeRegistry.current)
  }

  @objc private func themeDidChange() {
    apply(theme: FKThemeRegistry.current)
  }
}
