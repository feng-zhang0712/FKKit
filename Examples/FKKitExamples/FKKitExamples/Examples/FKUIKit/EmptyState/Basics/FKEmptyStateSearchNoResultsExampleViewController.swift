import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateSearchNoResultsExampleViewController: UIViewController {
  private let container = UIView()
  private let queryField = UITextField()
  private let filtersLabel = UILabel()
  private var activeFilters = 3
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "No Results"
    view.backgroundColor = .systemBackground
    buildUI()
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.render()
    }
    render()
  }

  private func buildUI() {
    queryField.borderStyle = .roundedRect
    queryField.placeholder = "Search query"
    queryField.text = "wireless earbuds pro max"
    queryField.addTarget(self, action: #selector(queryChanged), for: .editingChanged)

    filtersLabel.font = .systemFont(ofSize: 13, weight: .medium)
    filtersLabel.textColor = .secondaryLabel

    container.translatesAutoresizingMaskIntoConstraints = false
    queryField.translatesAutoresizingMaskIntoConstraints = false
    filtersLabel.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(queryField)
    view.addSubview(filtersLabel)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      queryField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      queryField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      queryField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      filtersLabel.topAnchor.constraint(equalTo: queryField.bottomAnchor, constant: 8),
      filtersLabel.leadingAnchor.constraint(equalTo: queryField.leadingAnchor),
      container.topAnchor.constraint(equalTo: filtersLabel.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func queryChanged() {
    render()
  }

  private func render() {
    let _ = queryField.text?.isEmpty == false ? (queryField.text ?? "") : "camera"
    filtersLabel.text = "Active filters: \(activeFilters)"

    var model = FKEmptyStateConfiguration.scenario(.noSearchResult)
    model.content.setImage(UIImage(systemName: "magnifyingglass"))
    model.actions = FKEmptyStateActionSet()
    container.fk_applyEmptyState(model)
  }
}
