import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateI18nExampleViewController: UIViewController {
  private let container = UIView()
  private let localeSelector = UISegmentedControl(items: ["en", "zh-Hans"])
  private let queryField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "i18n"
    view.backgroundColor = .systemBackground
    buildUI()
    render()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      FKI18nExampleSupport.syncWithDeviceLanguage()
    }
  }

  private func buildUI() {
    localeSelector.selectedSegmentIndex = FKI18nManager.shared.currentLanguageCode == "zh-Hans" ? 1 : 0
    localeSelector.addTarget(self, action: #selector(render), for: .valueChanged)
    localeSelector.translatesAutoresizingMaskIntoConstraints = false

    queryField.borderStyle = .roundedRect
    queryField.text = "wallet"
    queryField.placeholder = "query"
    queryField.addTarget(self, action: #selector(render), for: .editingChanged)
    queryField.translatesAutoresizingMaskIntoConstraints = false

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(localeSelector)
    view.addSubview(queryField)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      localeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      localeSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      localeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      queryField.topAnchor.constraint(equalTo: localeSelector.bottomAnchor, constant: 8),
      queryField.leadingAnchor.constraint(equalTo: localeSelector.leadingAnchor),
      queryField.trailingAnchor.constraint(equalTo: localeSelector.trailingAnchor),
      container.topAnchor.constraint(equalTo: queryField.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func render() {
    let code = localeSelector.selectedSegmentIndex == 0 ? "en" : "zh-Hans"
    FKI18nManager.shared.setLanguageCode(code)

    var model = FKEmptyStateConfiguration.scenario(.noSearchResult)
    model.content.setImage(UIImage(systemName: "magnifyingglass.circle"))
    model.actions = FKEmptyStateActionSet()
    container.fk_applyEmptyState(model)
  }
}
