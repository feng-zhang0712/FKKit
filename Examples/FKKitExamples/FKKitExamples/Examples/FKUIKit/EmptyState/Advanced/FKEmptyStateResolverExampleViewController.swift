import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateResolverExampleViewController: UIViewController {
  private let container = UIView()
  private var languageObservation: FKI18nObservationToken?
  private let loadingSwitch = UISwitch()
  private let offlineSwitch = UISwitch()
  private let permissionSwitch = UISwitch()
  private let dataCountField = UITextField()
  private let queryField = UITextField()
  private let errorField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "State Resolver"
    view.backgroundColor = .systemBackground
    buildUI()
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.recompute()
    }
    recompute()
  }

  private func buildUI() {
    let controls = UIStackView(arrangedSubviews: [
      makeSwitchRow("Loading", loadingSwitch),
      makeSwitchRow("Offline", offlineSwitch),
      makeSwitchRow("Has permission", permissionSwitch),
      makeFieldRow("Data count", dataCountField, initial: "0"),
      makeFieldRow("Search query", queryField, initial: "headset"),
      makeFieldRow("Error text", errorField, initial: ""),
    ])
    controls.axis = .vertical
    controls.spacing = 8
    controls.translatesAutoresizingMaskIntoConstraints = false

    permissionSwitch.isOn = true
    [loadingSwitch, offlineSwitch, permissionSwitch].forEach { $0.addTarget(self, action: #selector(recompute), for: .valueChanged) }
    [dataCountField, queryField, errorField].forEach { $0.addTarget(self, action: #selector(recompute), for: .editingChanged) }

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(controls)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      container.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func makeSwitchRow(_ title: String, _ control: UISwitch) -> UIView {
    let label = UILabel()
    label.text = title
    let row = UIStackView(arrangedSubviews: [label, UIView(), control])
    row.axis = .horizontal
    row.alignment = .center
    return row
  }

  private func makeFieldRow(_ title: String, _ field: UITextField, initial: String) -> UIView {
    let label = UILabel()
    label.text = title
    label.widthAnchor.constraint(equalToConstant: 110).isActive = true
    field.text = initial
    field.borderStyle = .roundedRect
    let row = UIStackView(arrangedSubviews: [label, field])
    row.axis = .horizontal
    row.spacing = 8
    return row
  }

  @objc private func recompute() {
    // Build a deterministic input snapshot from controls.
    // Treating UI as source-of-truth helps example resolver precedence without hidden state.
    let input = FKEmptyStateInputs(
      dataLength: Int(dataCountField.text ?? "0"),
      isLoading: loadingSwitch.isOn,
      errorDescription: errorField.text?.isEmpty == true ? nil : errorField.text,
      searchQuery: queryField.text,
      hasPermission: permissionSwitch.isOn,
      isOffline: offlineSwitch.isOn,
      isNewUser: false
    )

    let resolution = FKEmptyStateResolver.resolve(input)
    switch resolution {
    case .none:
      container.fk_hideEmptyState()
    case .show:
      let model = FKEmptyStateConfiguration.resolved(from: input)
      container.fk_applyEmptyState(model, actionHandler: { [weak self] _ in
        self?.errorField.text = ""
        self?.loadingSwitch.isOn = false
        self?.fk_presentMessageAlert(title: "Retry", message: "Retry pressed. Error input has been cleared.")
        self?.recompute()
      })
    }
  }
}
