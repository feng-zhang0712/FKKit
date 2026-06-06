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
