import Foundation
import UIKit

// MARK: - Header / footer

/// Section supplementary content model shared by table and collection lists.
public enum FKListSectionHeaderFooter: Hashable, Sendable {
  case title(String)
  case subtitle(title: String, subtitle: String?)
  case custom(viewProviderID: String)
}

// MARK: - Layout hints

/// Hashable content inset values for collection compositional layouts.
public struct FKListDirectionalInsets: Hashable, Sendable {
  public var top: CGFloat
  public var leading: CGFloat
  public var bottom: CGFloat
  public var trailing: CGFloat

  public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
    self.top = top
    self.leading = leading
    self.bottom = bottom
    self.trailing = trailing
  }

  public var directionalEdgeInsets: NSDirectionalEdgeInsets {
    NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
  }
}

/// Optional per-section layout hints for collection compositional layouts.
public struct FKListSectionLayoutHints: Hashable, Sendable {
  public var interGroupSpacing: CGFloat?
  public var contentInsets: FKListDirectionalInsets?

  public init(
    interGroupSpacing: CGFloat? = nil,
    contentInsets: FKListDirectionalInsets? = nil
  ) {
    self.interGroupSpacing = interGroupSpacing
    self.contentInsets = contentInsets
  }
}

// MARK: - Section

/// A diffable section with items and optional header/footer metadata.
public struct FKListSection: Hashable, Sendable {
  public var id: FKListSectionID
  public var items: [FKListItem]
  public var header: FKListSectionHeaderFooter?
  /// Table-only today: rendered by ``FKDiffableTableViewController``; ignored by collection lists.
  public var footer: FKListSectionHeaderFooter?
  public var layoutHints: FKListSectionLayoutHints?

  public init(
    id: FKListSectionID,
    items: [FKListItem] = [],
    header: FKListSectionHeaderFooter? = nil,
    footer: FKListSectionHeaderFooter? = nil,
    layoutHints: FKListSectionLayoutHints? = nil
  ) {
    self.id = id
    self.items = items
    self.header = header
    self.footer = footer
    self.layoutHints = layoutHints
  }
}
