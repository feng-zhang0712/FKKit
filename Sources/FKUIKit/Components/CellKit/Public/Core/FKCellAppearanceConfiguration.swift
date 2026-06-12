import UIKit

/// Global appearance defaults for CellKit rows and section chrome.
///
/// Assign ``FKCellAppearanceConfiguration/default`` at launch or pass per-row overrides through ``apply(_:)``.
public struct FKCellAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleTextStyle: FKCellTextStyle
  public var subtitleTextStyle: FKCellTextStyle
  public var detailTextStyle: FKCellTextStyle
  public var linkColor: UIColor
  public var destructiveColor: UIColor
  public var secondaryLabelColor: UIColor
  public var groupedBackgroundColor: UIColor
  public var cellBackgroundColor: UIColor
  public var cornerRadius: CGFloat
  public var horizontalMargin: CGFloat
  public var contentInsets: UIEdgeInsets
  public var minimumRowHeight: CGFloat

  /// Shared defaults aligned with iOS inset grouped settings styling.
  @MainActor
  public static var `default`: FKCellAppearanceConfiguration {
    FKCellAppearanceConfiguration(
      titleTextStyle: .body,
      subtitleTextStyle: .subheadline,
      detailTextStyle: .subheadline,
      linkColor: .systemBlue,
      destructiveColor: .systemRed,
      secondaryLabelColor: .secondaryLabel,
      groupedBackgroundColor: .systemGroupedBackground,
      cellBackgroundColor: .secondarySystemGroupedBackground,
      cornerRadius: 10,
      horizontalMargin: 20,
      contentInsets: UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16),
      minimumRowHeight: 44
    )
  }

  /// Creates an appearance configuration.
  public init(
    titleTextStyle: FKCellTextStyle = .body,
    subtitleTextStyle: FKCellTextStyle = .subheadline,
    detailTextStyle: FKCellTextStyle = .subheadline,
    linkColor: UIColor = .systemBlue,
    destructiveColor: UIColor = .systemRed,
    secondaryLabelColor: UIColor = .secondaryLabel,
    groupedBackgroundColor: UIColor = .systemGroupedBackground,
    cellBackgroundColor: UIColor = .secondarySystemGroupedBackground,
    cornerRadius: CGFloat = 10,
    horizontalMargin: CGFloat = 20,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16),
    minimumRowHeight: CGFloat = 44
  ) {
    self.titleTextStyle = titleTextStyle
    self.subtitleTextStyle = subtitleTextStyle
    self.detailTextStyle = detailTextStyle
    self.linkColor = linkColor
    self.destructiveColor = destructiveColor
    self.secondaryLabelColor = secondaryLabelColor
    self.groupedBackgroundColor = groupedBackgroundColor
    self.cellBackgroundColor = cellBackgroundColor
    self.cornerRadius = cornerRadius
    self.horizontalMargin = horizontalMargin
    self.contentInsets = contentInsets
    self.minimumRowHeight = minimumRowHeight
  }
}

extension FKCellAppearanceConfiguration {
  public static func == (lhs: FKCellAppearanceConfiguration, rhs: FKCellAppearanceConfiguration) -> Bool {
    lhs.titleTextStyle == rhs.titleTextStyle
      && lhs.subtitleTextStyle == rhs.subtitleTextStyle
      && lhs.detailTextStyle == rhs.detailTextStyle
      && lhs.linkColor.isEqual(rhs.linkColor)
      && lhs.destructiveColor.isEqual(rhs.destructiveColor)
      && lhs.secondaryLabelColor.isEqual(rhs.secondaryLabelColor)
      && lhs.groupedBackgroundColor.isEqual(rhs.groupedBackgroundColor)
      && lhs.cellBackgroundColor.isEqual(rhs.cellBackgroundColor)
      && lhs.cornerRadius == rhs.cornerRadius
      && lhs.horizontalMargin == rhs.horizontalMargin
      && lhs.contentInsets == rhs.contentInsets
      && lhs.minimumRowHeight == rhs.minimumRowHeight
  }
}
