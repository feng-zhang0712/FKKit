import FKCoreKit
import FKUIKit
import UIKit

private enum FKCellKitCollectionParitySection: Int, Sendable {
  case main
}

/// Standalone CellKit table integration without FKListKit (#12).
@MainActor
final class FKCellKitExampleStandaloneTableViewController: FKCellKitExampleTableViewController {
  init() {
    super.init(
      title: "Standalone Table",
      sections: [
        FKCellKitExampleSection(
          headerConfiguration: FKCellSectionHeaderConfiguration(title: "Account"),
          footerConfiguration: FKCellSectionFooterConfiguration(
            text: "Learn more about privacy settings.",
            linkRanges: [FKCellLinkRange(location: 0, length: 10, url: URL(string: "https://example.com/privacy")!)]
          ),
          rows: [
            FKCellKitExampleRow.make(FKCellDisclosureCell.self, title: "General") {
              $0.configure(with: FKCellDisclosureRow(id: "general", title: "General"))
            },
            FKCellKitExampleRow.make(FKCellDisclosureCell.self, title: "Privacy") {
              $0.configure(with: FKCellDisclosureRow(id: "privacy", title: "Privacy & Security", isLastInSection: true))
            },
          ]
        ),
        FKCellKitExampleSection(
          headerConfiguration: FKCellSectionHeaderConfiguration(title: "Support"),
          rows: [
            FKCellKitExampleRow.make(FKCellDisclosureCell.self, title: "Help") {
              $0.configure(with: FKCellDisclosureRow(id: "help", title: "Help Center"))
            },
          ]
        ),
      ]
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

/// Demonstrates ``FKListPresetItem`` → CellKit cell mapping.
@MainActor
final class FKCellKitExampleListPresetViewController: UITableViewController {
  private let presets: [FKListPresetItem] = [
    .disclosure(FKCellDisclosureRow(id: "d1", title: "Disclosure")),
    .subtitle(FKCellValueDisclosureRow(id: "s1", title: "Subtitle Row", value: "Value")),
    .customValue(FKCellValueDisclosureRow(id: "c1", title: "Custom Value", value: "42 GB")),
    .keyValue(FKCellKeyValueRow(id: "k1", title: "Version", value: "1.0.0")),
    .icon(FKCellIconDisclosureRow(id: "i1", icon: FKCellIconContent(symbolName: "wifi"), title: "Wi-Fi", showsDisclosure: true)),
    .switchRow(FKCellSwitchRow(id: "sw1", title: "Airplane Mode", isOn: false)),
    .checkbox(FKCellCheckboxRow(
      id: "cb1",
      configuration: FKCellCheckboxConfiguration(title: "Remember Me", isChecked: true)
    )),
  ]

  init() {
    super.init(style: .insetGrouped)
    title = "ListKit Presets"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    tableView.fk_registerCellKitCells(
      .table(FKCellDisclosureCell.self),
      .table(FKCellValueDisclosureCell.self),
      .table(FKCellKeyValueCell.self),
      .table(FKCellIconDisclosureCell.self),
      .table(FKCellSwitchCell.self),
      .table(FKCellCheckboxCell.self)
    )
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    presets.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = presets[indexPath.row]
    let cell: UITableViewCell
    switch item {
    case .disclosure:
      cell = tableView.dequeue(FKCellDisclosureCell.self, for: indexPath)
    case .subtitle, .customValue:
      cell = tableView.dequeue(FKCellValueDisclosureCell.self, for: indexPath)
    case .keyValue:
      cell = tableView.dequeue(FKCellKeyValueCell.self, for: indexPath)
    case .icon:
      cell = tableView.dequeue(FKCellIconDisclosureCell.self, for: indexPath)
    case .switchRow:
      cell = tableView.dequeue(FKCellSwitchCell.self, for: indexPath)
    case .checkbox:
      cell = tableView.dequeue(FKCellCheckboxCell.self, for: indexPath)
    }
    FKListPresetCellConfigurator.configure(cell: cell, with: item)
    if let switchCell = cell as? FKCellSwitchCell {
      switchCell.onValueChanged = { isOn in
        FKToast.show("Switch: \(isOn ? "On" : "Off")")
      }
    }
    return cell
  }
}

/// Collection view parity for shared Internal renderers.
@MainActor
final class FKCellKitExampleCollectionParityViewController: UIViewController {
  private var dataSource: UICollectionViewDiffableDataSource<FKCellKitCollectionParitySection, String>!
  private let collectionView: UICollectionView

  init() {
    let layout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .insetGrouped))
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
    title = "Collection Parity"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    collectionView.fk_registerCellKitCollectionCells(
      .collection(FKCellDisclosureCollectionCell.self),
      .collection(FKCellValueDisclosureCollectionCell.self),
      .collection(FKCellSwitchCollectionCell.self),
      .collection(FKCellProfileCollectionCell.self),
      .collection(FKCellConversationCollectionCell.self)
    )
    configureDataSource()
    applySnapshot()
  }

  private func configureDataSource() {
    let disclosure = UICollectionView.CellRegistration<FKCellDisclosureCollectionCell, String> { cell, _, id in
      cell.configure(with: FKCellDisclosureRow(id: id, title: "Disclosure \(id)"))
    }
    let value = UICollectionView.CellRegistration<FKCellValueDisclosureCollectionCell, String> { cell, _, id in
      cell.configure(with: FKCellValueDisclosureRow(id: id, title: "Value Row", value: "Detail"))
    }
    let switchReg = UICollectionView.CellRegistration<FKCellSwitchCollectionCell, String> { cell, _, id in
      cell.configure(with: FKCellSwitchRow(id: id, title: "Toggle \(id)", isOn: id.hasSuffix("2")))
      cell.onValueChanged = { isOn in FKToast.show("\(id): \(isOn ? "On" : "Off")") }
    }
    let profile = UICollectionView.CellRegistration<FKCellProfileCollectionCell, String> { cell, _, id in
      cell.configure(with: FKCellProfileRow(
        id: id,
        configuration: FKCellProfileConfiguration(title: "Alex Morgan", subtitle: "Product Designer")
      ))
    }
    let conversation = UICollectionView.CellRegistration<FKCellConversationCollectionCell, String> { cell, _, id in
      cell.configure(with: FKCellConversationRow(
        id: id,
        configuration: FKCellConversationConfiguration(
          title: "Design Team",
          preview: "Latest mockups are ready for review.",
          timestamp: "2:30 PM",
          unread: FKCellUnreadPresentation(isUnread: true, badgeCount: 2)
        )
      ))
    }

    dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, id in
      switch indexPath.item {
      case 0: return collectionView.dequeueConfiguredReusableCell(using: disclosure, for: indexPath, item: id)
      case 1: return collectionView.dequeueConfiguredReusableCell(using: value, for: indexPath, item: id)
      case 2: return collectionView.dequeueConfiguredReusableCell(using: switchReg, for: indexPath, item: id)
      case 3: return collectionView.dequeueConfiguredReusableCell(using: profile, for: indexPath, item: id)
      default: return collectionView.dequeueConfiguredReusableCell(using: conversation, for: indexPath, item: id)
      }
    }
  }

  private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<FKCellKitCollectionParitySection, String>()
    snapshot.appendSections([.main])
    snapshot.appendItems(["1", "2", "3", "4", "5"])
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

/// Optional stress scroll with repeated disclosure rows.
@MainActor
final class FKCellKitExampleStressScrollViewController: FKCellKitExampleTableViewController {
  init() {
    let rows = (0..<200).map { index in
      FKCellKitExampleRow.make(FKCellDisclosureCell.self, title: "Row \(index)") {
        $0.configure(with: FKCellDisclosureRow(id: "row-\(index)", title: "Settings Item \(index)"))
      }
    }
    super.init(
      title: "Stress Scroll",
      sections: [FKCellKitExampleSection(title: "Performance", footer: "200 disclosure rows.", rows: rows)]
    )
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
