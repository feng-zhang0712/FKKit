import FKCoreKit
import FKUIKit
import UIKit

enum FKEmptyStateExampleFactory {
  static func configureGlobalStyleIfNeeded() {
    FKEmptyState.configureAppearance { appearance in
      appearance.background.color = .systemBackground
      appearance.typography.titleColor = .label
      appearance.typography.descriptionColor = .secondaryLabel
      appearance.typography.titleFont = .systemFont(ofSize: 20, weight: .semibold)
      appearance.typography.descriptionFont = .systemFont(ofSize: 15, weight: .regular)
      appearance.buttons.primary = FKEmptyStateButtonStyle(
        titleColor: .white,
        font: .systemFont(ofSize: 15, weight: .semibold),
        backgroundColor: .systemBlue,
        cornerRadius: 12,
        contentInsets: UIEdgeInsets(top: 11, left: 18, bottom: 11, right: 18)
      )
    }
    FKEmptyState.configureLayout { layout in
      layout.verticalSpacing = 12
      layout.contentInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
    }
  }

  /// Favorites empty preset — title, description, and primary action come from bundled FKUIKit strings.
  static func makeBasicModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noFavorites)
    model.layout.context = .section
    return model
  }

  /// Offline / no-network preset — uses ``FKEmptyStateScenario/noNetwork`` bundled copy.
  static func makeNoNetworkModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noNetwork)
    let retryTitle = model.actions.primary?.title ?? "Retry"
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "retry", title: retryTitle, kind: .primary),
      secondary: FKEmptyStateAction(id: "docs", title: "Check network settings", kind: .secondary)
    )
    model.appearance.buttons.secondary = FKEmptyStateButtonStyle(
      titleColor: .secondaryLabel,
      font: .systemFont(ofSize: 15, weight: .medium),
      backgroundColor: .clear,
      cornerRadius: 10,
      contentInsets: UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16),
      borderColor: .separator,
      borderWidth: 1
    )
    return model
  }

  /// Load-failed preset — uses ``FKEmptyStateScenario/loadFailed`` bundled copy.
  static func makeLoadFailedModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.loadFailed)
    model.content.setImage(UIImage(systemName: "exclamationmark.arrow.trianglehead.clockwise"))
    return model
  }

  static func makeCustomEmptyModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration(
      phase: .empty,
      image: UIImage(systemName: "shippingbox"),
      title: "No Items Yet",
      description: "Create your first item and it will appear here.",
      primaryActionTitle: "Create Item"
    )
    model.appearance.typography.titleColor = .systemIndigo
    model.appearance.typography.descriptionColor = .systemGray
    model.appearance.buttons.primary.backgroundColor = .systemIndigo
    return model
  }

  static func makeMaintenanceModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.customState(
      identifier: "maintenance",
      title: "Service Under Maintenance",
      description: "We are upgrading the service. Please try again later.",
      buttonTitle: "Refresh Status"
    )
    model.content.setImage(UIImage(systemName: "wrench.and.screwdriver"))
    model.layout.contentAlignment = .top
    model.layout.verticalOffset = 40
    return model
  }

  /// Long localized copy for full-page layout wrapping demos.
  static func makeLongTextModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noMessages)
    model.content.setImage(UIImage(systemName: "tray.full"))
    model.actions = FKEmptyStateActionSet()
    return model
  }

  static func makeIconOnlyModel() -> FKEmptyStateConfiguration {
    FKEmptyStateConfiguration(
      phase: .empty,
      type: .empty,
      image: UIImage(systemName: "sparkles"),
      title: nil,
      description: nil
    )
  }
}

extension UIViewController {
  /// Re-applies empty-state content when ``FKI18nManager`` language changes.
  @discardableResult
  func fk_observeEmptyStateLanguageRefresh(reload: @escaping @MainActor () -> Void) -> FKI18nObservationToken {
    FKI18nManager.shared.observeLanguageChange { _ in
      Task { @MainActor in reload() }
    }
  }

  func fk_presentMessageAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.common.ok"), style: .default))
    present(alert, animated: true)
  }

  func fk_embedFill(_ subview: UIView, in container: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: container.topAnchor),
      subview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      subview.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  func fk_makeSectionContainer() -> UIView {
    let container = UIView()
    container.backgroundColor = .secondarySystemBackground
    container.layer.cornerRadius = 12
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }
}

// MARK: - Playground layout helpers

enum FKEmptyStateExamplePlaygroundSupport {
  private enum Metrics {
    static let screenMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 28, trailing: 16)
    static let cardSpacing: CGFloat = 16
    static let cardPadding = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    static let cardContentSpacing: CGFloat = 12
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

  static func sectionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    return label
  }

  static func labeledRow(title: String, control: UIView) -> UIStackView {
    let name = UILabel()
    name.text = title
    name.font = .preferredFont(forTextStyle: .subheadline)
    name.textColor = .label
    name.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    name.setContentCompressionResistancePriority(.required, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [name, control])
    row.axis = .horizontal
    row.spacing = 12
    row.alignment = .center
    control.setContentHuggingPriority(.defaultLow, for: .horizontal)
    return row
  }

  static func sliderRow(
    title: String,
    slider: UISlider,
    valueLabel: UILabel,
    format: @escaping (Float) -> String
  ) -> UIStackView {
    slider.addAction(UIAction { _ in
      valueLabel.text = format(slider.value)
    }, for: .valueChanged)

    let valueColumn = UIStackView(arrangedSubviews: [slider, valueLabel])
    valueColumn.axis = .vertical
    valueColumn.spacing = 4

    valueLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    valueLabel.textColor = .tertiaryLabel
    valueLabel.text = format(slider.value)

    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 6
    column.addArrangedSubview(labeledRow(title: title, control: valueColumn))
    return column
  }

  static func makePreviewContainer(height: CGFloat = 240) -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .tertiarySystemGroupedBackground
    container.layer.cornerRadius = 12
    container.layer.cornerCurve = .continuous
    container.clipsToBounds = true
    container.heightAnchor.constraint(equalToConstant: height).isActive = true
    return container
  }

  /// Scroll view for playground controls (preview stays fixed above so pan gestures are not blocked).
  static func makeControlsScrollStack(arrangedSubviews: [UIView]) -> UIScrollView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true
    scroll.contentInsetAdjustmentBehavior = .never
    scroll.keyboardDismissMode = .onDrag

    let stack = UIStackView(arrangedSubviews: arrangedSubviews)
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
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -Metrics.screenMargins.bottom),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
    ])

    return scroll
  }
}
