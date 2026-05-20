import FKCoreKit
import UIKit

// MARK: - Demo models & cells

private struct PluggableRowViewModel: Sendable, Hashable {
  let title: String
  let subtitle: String
}

/// Demonstrates `FKCellReusable` + `UITableView.register/dequeue` helpers.
private final class PluggableDemoCell: UITableViewCell, FKCellReusable {
  func configure(with viewModel: PluggableRowViewModel) {
    var config = defaultContentConfiguration()
    config.text = viewModel.title
    config.secondaryText = viewModel.subtitle
    contentConfiguration = config
    accessoryType = .disclosureIndicator
  }
}

/// Demonstrates `FKListTableCellConfigurable` (ListKit-style binding).
private final class PluggableConfigurableCell: UITableViewCell, FKListTableCellConfigurable {
  func configure(with item: PluggableRowViewModel) {
    var config = defaultContentConfiguration()
    config.text = "[Configurable] \(item.title)"
    config.secondaryText = item.subtitle
    contentConfiguration = config
  }
}

/// Demonstrates `FKListCollectionCellConfigurable` + `UICollectionView` helpers.
private final class PluggableCollectionCell: UICollectionViewCell, FKListCollectionCellConfigurable {
  func configure(with item: PluggableRowViewModel) {
    var config = UIListContentConfiguration.cell()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.textProperties.alignment = .center
    contentConfiguration = config
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 8
  }
}

// MARK: - View controller

/// Interactive table demo for list-cell pluggable protocols.
@MainActor
final class FKPluggableListCellExampleViewController: UIViewController {

  private let headerPanel = UIStackView()
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private let collectionView: UICollectionView

  private let reusableItems: [PluggableRowViewModel] = [
    PluggableRowViewModel(title: "FKCellReusable", subtitle: "Default reuseIdentifier + configure(with:)"),
    PluggableRowViewModel(title: "Row 2", subtitle: "Dequeued via tableView.dequeue(_:for:)"),
  ]
  private let configurableItems: [PluggableRowViewModel] = [
    PluggableRowViewModel(title: "FKListTableCellConfigurable", subtitle: "Associatedtype Item binding"),
  ]
  private var mode: Mode = .reusable

  private enum Mode: String {
    case reusable = "FKCellReusable"
    case configurable = "FKListTableCellConfigurable"
  }

  private let modeControl = UISegmentedControl(items: [Mode.reusable.rawValue, Mode.configurable.rawValue])

  init() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = CGSize(width: 200, height: 72)
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · List Cells"
    view.backgroundColor = .systemGroupedBackground

    modeControl.selectedSegmentIndex = 0
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

    headerPanel.axis = .vertical
    headerPanel.spacing = 12
    headerPanel.translatesAutoresizingMaskIntoConstraints = false
    headerPanel.addArrangedSubview(modeControl)
    headerPanel.addArrangedSubview(collectionView)

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.dataSource = self
    collectionView.register(PluggableCollectionCell.self)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(PluggableDemoCell.self)
    tableView.register(
      PluggableConfigurableCell.self,
      forCellReuseIdentifier: String(describing: PluggableConfigurableCell.self)
    )

    view.addSubview(headerPanel)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      headerPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      headerPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      headerPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      collectionView.heightAnchor.constraint(equalToConstant: 88),

      tableView.topAnchor.constraint(equalTo: headerPanel.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  @objc private func modeChanged() {
    mode = modeControl.selectedSegmentIndex == 0 ? .reusable : .configurable
    tableView.reloadData()
  }
}

extension FKPluggableListCellExampleViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    mode == .reusable ? reusableItems.count : configurableItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch mode {
    case .reusable:
      let cell = tableView.dequeue(PluggableDemoCell.self, for: indexPath)
      cell.configure(with: reusableItems[indexPath.row])
      return cell
    case .configurable:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: String(describing: PluggableConfigurableCell.self),
        for: indexPath
      ) as! PluggableConfigurableCell
      cell.configure(with: configurableItems[indexPath.row])
      return cell
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "Mode: \(mode.rawValue) · reuseId=\(PluggableDemoCell.reuseIdentifier)"
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    "Horizontal collection below demonstrates FKListCollectionCellConfigurable."
  }
}

extension FKPluggableListCellExampleViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    configurableItems.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeue(PluggableCollectionCell.self, for: indexPath)
    cell.configure(with: configurableItems[indexPath.item])
    return cell
  }
}
