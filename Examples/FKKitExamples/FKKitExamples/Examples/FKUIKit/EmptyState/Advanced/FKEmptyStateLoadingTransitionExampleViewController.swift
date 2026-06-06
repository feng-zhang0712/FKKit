import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateLoadingTransitionExampleViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private let simulateButton = UIButton(type: .system)
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loading -> Empty"
    view.backgroundColor = .systemBackground
    buildUI()
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.showLoading()
    }
    showLoading()
  }

  private func buildUI() {
    simulateButton.translatesAutoresizingMaskIntoConstraints = false
    simulateButton.setTitle("Simulate Loading Flow", for: .normal)
    simulateButton.addTarget(self, action: #selector(showLoading), for: .touchUpInside)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self

    view.addSubview(simulateButton)
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      simulateButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      simulateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      tableView.topAnchor.constraint(equalTo: simulateButton.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func showLoading() {
    let skeleton = makeSkeletonAccessory()
    var model = FKEmptyStateConfiguration(
      phase: .loading,
      type: .loading,
      title: FKUIKitI18n.string("fkuikit.common.loading")
    )
    model.content.customAccessory = FKEmptyStateCustomAccessory(view: skeleton, placement: .belowDescription)
    model.presentation.loadingBehavior.hidesDescription = true
    tableView.fk_applyEmptyState(model, animated: false)

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
      guard let self else { return }
      let empty = FKEmptyStateExampleFactory.makeBasicModel()
      // In-place handoff: no content transition while the overlay stays visible.
      self.tableView.fk_updateEmptyState(empty, animated: false)
    }
  }

  private func makeSkeletonAccessory() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.widthAnchor.constraint(equalToConstant: 220).isActive = true

    for width in [220, 180, 200] {
      let bar = UIView()
      bar.backgroundColor = .tertiarySystemFill
      bar.layer.cornerRadius = 6
      bar.translatesAutoresizingMaskIntoConstraints = false
      bar.heightAnchor.constraint(equalToConstant: 12).isActive = true
      bar.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
      stack.addArrangedSubview(bar)
    }
    return stack
  }
}

extension FKEmptyStateLoadingTransitionExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
}
