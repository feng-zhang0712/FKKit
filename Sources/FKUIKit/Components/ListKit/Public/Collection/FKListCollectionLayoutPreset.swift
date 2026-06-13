import UIKit

/// Built-in compositional layout presets for collection list controllers.
public enum FKListCollectionLayoutPreset: Sendable, Equatable {
  /// Full-width vertical list rows.
  case list
  /// Uniform grid with fixed column count.
  case grid(columns: Int, spacing: CGFloat)
  /// Inset grouped card sections similar to Settings.
  case insetGroupedList

  /// Whether preset collection cells should render per-item card chrome.
  var displaysCollectionCardChrome: Bool {
    switch self {
    case .grid:
      return true
    case .list, .insetGroupedList:
      return false
    }
  }
}

/// Builds compositional layouts for ``FKDiffableCollectionViewController``.
@MainActor
public enum FKListCollectionLayoutFactory {
  public static func makeLayout(
    preset: FKListCollectionLayoutPreset,
    snapshot: FKListSnapshot
  ) -> UICollectionViewLayout {
    switch preset {
    case .list:
      return makeListLayout(snapshot: snapshot)
    case .grid(let columns, let spacing):
      return makeGridLayout(columns: columns, spacing: spacing, snapshot: snapshot)
    case .insetGroupedList:
      return makeInsetGroupedLayout(snapshot: snapshot)
    }
  }

  private static func makeListLayout(snapshot: FKListSnapshot) -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(52))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 0
      if sectionHasHeader(snapshot: snapshot, sectionIndex: sectionIndex) {
        section.boundarySupplementaryItems = [sectionHeaderSupplementaryItem()]
      }
      if snapshot.sections.indices.contains(sectionIndex),
         let spacing = snapshot.sections[sectionIndex].layoutHints?.interGroupSpacing {
        section.interGroupSpacing = spacing
      }
      return section
    }
  }

  private static func makeGridLayout(
    columns: Int,
    spacing: CGFloat,
    snapshot: FKListSnapshot
  ) -> UICollectionViewLayout {
    let count = max(1, columns)
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(120))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(120))
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
      group.interItemSpacing = .fixed(spacing)
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = spacing
      if sectionHasHeader(snapshot: snapshot, sectionIndex: sectionIndex) {
        section.boundarySupplementaryItems = [sectionHeaderSupplementaryItem()]
      }
      if snapshot.sections.indices.contains(sectionIndex),
         let hintSpacing = snapshot.sections[sectionIndex].layoutHints?.interGroupSpacing {
        section.interGroupSpacing = hintSpacing
      }
      return section
    }
  }

  private static func sectionHeaderSupplementaryItem() -> NSCollectionLayoutBoundarySupplementaryItem {
    let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(32))
    let item = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: size,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )
    item.pinToVisibleBounds = true
    return item
  }

  private static func sectionHasHeader(snapshot: FKListSnapshot, sectionIndex: Int) -> Bool {
    guard snapshot.sections.indices.contains(sectionIndex) else { return false }
    return snapshot.sections[sectionIndex].header != nil
  }

  private static func makeInsetGroupedLayout(snapshot: FKListSnapshot) -> UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(52))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(52))
      let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 0
      let horizontalInset: CGFloat = 16
      section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: horizontalInset, bottom: 8, trailing: horizontalInset)
      if snapshot.sections.indices.contains(sectionIndex),
         let hints = snapshot.sections[sectionIndex].layoutHints {
        if let insets = hints.contentInsets {
          section.contentInsets = insets.directionalEdgeInsets
        }
        if let spacing = hints.interGroupSpacing {
          section.interGroupSpacing = spacing
        }
      }
      if sectionHasHeader(snapshot: snapshot, sectionIndex: sectionIndex) {
        section.boundarySupplementaryItems = [sectionHeaderSupplementaryItem()]
      }
      let background = NSCollectionLayoutDecorationItem.background(elementKind: FKListCollectionBackgroundDecoration.kind)
      section.decorationItems = [background]
      return section
    }
  }
}

/// Decoration kind for inset grouped section backgrounds.
enum FKListCollectionBackgroundDecoration {
  static let kind = "FKListCollectionBackgroundDecoration"
}

/// Inputs that affect compositional layout construction (excluding item payloads).
struct FKListCollectionLayoutStructureSignature: Equatable {
  let preset: FKListCollectionLayoutPreset
  let sections: [Section]

  struct Section: Equatable {
    let id: FKListSectionID
    let hasHeader: Bool
    let layoutHints: FKListSectionLayoutHints?
  }

  init(preset: FKListCollectionLayoutPreset, snapshot: FKListSnapshot) {
    self.preset = preset
    self.sections = snapshot.sections.map {
      Section(id: $0.id, hasHeader: $0.header != nil, layoutHints: $0.layoutHints)
    }
  }
}

/// Rounded background for inset grouped collection sections.
@MainActor
final class FKListCollectionBackgroundView: UICollectionReusableView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .secondarySystemGroupedBackground
    layer.cornerRadius = 12
    layer.masksToBounds = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
