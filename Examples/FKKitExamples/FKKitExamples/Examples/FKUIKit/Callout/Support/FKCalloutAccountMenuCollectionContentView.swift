import UIKit
import FKUIKit

enum FKCalloutAccountMenuCollectionSection: Int, CaseIterable, Sendable {
  case workspaces
  case highlight
  case shortcuts
  case signOut
}

struct FKCalloutAccountMenuCollectionRow: Hashable, Sendable {
  let id: String
  let title: String
  let subtitle: String?
  let symbolName: String?
  let isSelected: Bool
  let isDestructive: Bool
  let usesAccentTint: Bool
}

/// Compact account/workspace menu for ``FKPopover/show(customView:)`` demos (single-column list).
@MainActor
final class FKCalloutAccountMenuCollectionContentView: UIView {
  typealias Section = FKCalloutAccountMenuCollectionSection
  typealias Row = FKCalloutAccountMenuCollectionRow

  static let preferredContentSize = CGSize(width: 272, height: 388)

  var onSelect: ((Row) -> Void)?

  private static let rowsBySection: [Section: [Row]] = [
    .workspaces: [
      Row(
        id: "workspace",
        title: "DesignDrops.io",
        subtitle: "Essentials · 1 member",
        symbolName: nil,
        isSelected: true,
        isDestructive: false,
        usesAccentTint: true
      ),
      Row(
        id: "personal",
        title: "Personal",
        subtitle: "Essentials · 1 member",
        symbolName: nil,
        isSelected: false,
        isDestructive: false,
        usesAccentTint: false
      ),
    ],
    .highlight: [
      Row(
        id: "invite",
        title: "Invite members",
        subtitle: nil,
        symbolName: "person.badge.plus",
        isSelected: false,
        isDestructive: false,
        usesAccentTint: true
      ),
    ],
    .shortcuts: [
      Row(id: "account", title: "My account", subtitle: nil, symbolName: "person", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "settings", title: "Settings", subtitle: nil, symbolName: "gearshape", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "integrations", title: "Integrations", subtitle: nil, symbolName: "point.3.connected.trianglepath.dotted", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "labs", title: "Labs", subtitle: nil, symbolName: "flask", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "members", title: "Members", subtitle: nil, symbolName: "person.2", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "teams", title: "Teams", subtitle: nil, symbolName: "person.3", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "billing", title: "Billing", subtitle: nil, symbolName: "creditcard", isSelected: false, isDestructive: false, usesAccentTint: false),
      Row(id: "terms", title: "Terms and Policies", subtitle: nil, symbolName: "doc.text", isSelected: false, isDestructive: false, usesAccentTint: false),
    ],
    .signOut: [
      Row(
        id: "signout",
        title: "Sign out",
        subtitle: nil,
        symbolName: "rectangle.portrait.and.arrow.right",
        isSelected: false,
        isDestructive: true,
        usesAccentTint: false
      ),
    ],
  ]

  private let collectionView: UICollectionView
  private var dataSource: UICollectionViewDiffableDataSource<Section, String>!
  private lazy var rowsByID: [String: Row] = {
    var map: [String: Row] = [:]
    Self.rowsBySection.values.flatMap { $0 }.forEach { map[$0.id] = $0 }
    return map
  }()

  override var intrinsicContentSize: CGSize {
    Self.preferredContentSize
  }

  override init(frame: CGRect) {
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.defaultLow, for: .horizontal)
    setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .vertical)
    collectionView.backgroundColor = .clear
    collectionView.isScrollEnabled = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    configureDataSource()
    applySnapshot()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  private static func makeLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { sectionIndex, _ in
      guard let section = Section(rawValue: sectionIndex) else { return nil }
      let itemHeight: CGFloat
      switch section {
      case .workspaces:
        itemHeight = 58
      case .highlight, .signOut, .shortcuts:
        itemHeight = 44
      }
      let item = NSCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight))
      )
      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)),
        subitems: [item]
      )
      let sectionLayout = NSCollectionLayoutSection(group: group)
      sectionLayout.interGroupSpacing = section == .workspaces ? 8 : 0
      switch section {
      case .workspaces:
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 36, leading: 12, bottom: 8, trailing: 12)
        let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28)),
          elementKind: UICollectionView.elementKindSectionHeader,
          alignment: .top
        )
        sectionLayout.boundarySupplementaryItems = [header]
      case .highlight:
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
      case .shortcuts:
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
      case .signOut:
        sectionLayout.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 12, trailing: 12)
      }
      return sectionLayout
    }
  }

  private func configureDataSource() {
    let workspaceRegistration = UICollectionView.CellRegistration<WorkspaceCell, String> { [weak self] cell, _, id in
      guard let row = self?.rowsByID[id] else { return }
      cell.apply(row)
    }
    let actionRegistration = UICollectionView.CellRegistration<ActionCell, String> { [weak self] cell, _, id in
      guard let row = self?.rowsByID[id] else { return }
      cell.apply(row)
    }
    let headerRegistration = UICollectionView.SupplementaryRegistration<HeaderView>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { view, _, _ in
      view.label.text = "eric.peters@designdrops.io"
    }

    dataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) {
      collectionView, indexPath, id in
      guard let section = Section(rawValue: indexPath.section),
            self.rowsByID[id] != nil
      else { return UICollectionViewCell() }
      switch section {
      case .workspaces:
        return collectionView.dequeueConfiguredReusableCell(using: workspaceRegistration, for: indexPath, item: id)
      case .highlight, .shortcuts, .signOut:
        return collectionView.dequeueConfiguredReusableCell(using: actionRegistration, for: indexPath, item: id)
      }
    }

    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      guard kind == UICollectionView.elementKindSectionHeader,
            Section(rawValue: indexPath.section) == .workspaces
      else { return nil }
      return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
    }

    collectionView.delegate = self
  }

  private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
    Section.allCases.forEach { section in
      snapshot.appendSections([section])
      snapshot.appendItems((Self.rowsBySection[section] ?? []).map(\.id), toSection: section)
    }
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

extension FKCalloutAccountMenuCollectionContentView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let id = dataSource.itemIdentifier(for: indexPath),
          let row = rowsByID[id]
    else { return }
    onSelect?(row)
  }
}

// MARK: - Cells

@MainActor
private final class HeaderView: UICollectionReusableView {
  let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    label.font = .systemFont(ofSize: 12, weight: .semibold)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}

@MainActor
private final class WorkspaceCell: UICollectionViewCell {
  private let rowStack = UIStackView()
  private let leadingSlot = UIView()
  private let textStack = UIStackView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 10
    contentView.clipsToBounds = true
    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
    subtitleLabel.textColor = .secondaryLabel
    checkmark.tintColor = .systemBlue
    checkmark.contentMode = .scaleAspectFit
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)
    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 10
    rowStack.isLayoutMarginsRelativeArrangement = true
    rowStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    rowStack.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingSlot.widthAnchor.constraint(equalToConstant: 20),
      checkmark.widthAnchor.constraint(equalToConstant: 14),
      checkmark.heightAnchor.constraint(equalToConstant: 14),
    ])
    leadingSlot.addSubview(checkmark)
    checkmark.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      checkmark.centerXAnchor.constraint(equalTo: leadingSlot.centerXAnchor),
      checkmark.centerYAnchor.constraint(equalTo: leadingSlot.centerYAnchor),
    ])
    rowStack.addArrangedSubview(leadingSlot)
    rowStack.addArrangedSubview(textStack)
    contentView.addSubview(rowStack)
    NSLayoutConstraint.activate([
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      rowStack.topAnchor.constraint(equalTo: contentView.topAnchor),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func apply(_ row: FKCalloutAccountMenuCollectionRow) {
    titleLabel.text = row.title
    subtitleLabel.text = row.subtitle
    titleLabel.textColor = row.usesAccentTint ? .systemBlue : .label
    checkmark.isHidden = !row.isSelected
    checkmark.alpha = row.isSelected ? 1 : 0
  }
}

@MainActor
private final class ActionCell: UICollectionViewCell {
  private let rowStack = UIStackView()
  private let leadingSlot = UIView()
  private let iconView = UIImageView()
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .clear
    iconView.contentMode = .scaleAspectFit
    iconView.tintColor = .label
    titleLabel.font = .systemFont(ofSize: 15)
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.spacing = 10
    rowStack.isLayoutMarginsRelativeArrangement = true
    rowStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    rowStack.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.translatesAutoresizingMaskIntoConstraints = false
    iconView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingSlot.widthAnchor.constraint(equalToConstant: 20),
      iconView.widthAnchor.constraint(equalToConstant: 20),
      iconView.heightAnchor.constraint(equalToConstant: 20),
    ])
    leadingSlot.addSubview(iconView)
    NSLayoutConstraint.activate([
      iconView.centerXAnchor.constraint(equalTo: leadingSlot.centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: leadingSlot.centerYAnchor),
    ])
    rowStack.addArrangedSubview(leadingSlot)
    rowStack.addArrangedSubview(titleLabel)
    contentView.addSubview(rowStack)
    NSLayoutConstraint.activate([
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      rowStack.topAnchor.constraint(equalTo: contentView.topAnchor),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  func apply(_ row: FKCalloutAccountMenuCollectionRow) {
    titleLabel.text = row.title
    let showsIcon = row.symbolName != nil
    iconView.image = row.symbolName.flatMap { UIImage(systemName: $0) }
    leadingSlot.isHidden = !showsIcon
    if row.isDestructive {
      iconView.tintColor = .systemRed
      titleLabel.textColor = .systemRed
    } else if row.usesAccentTint {
      iconView.tintColor = .systemBlue
      titleLabel.textColor = .systemBlue
    } else {
      iconView.tintColor = .label
      titleLabel.textColor = .label
    }
  }
}
