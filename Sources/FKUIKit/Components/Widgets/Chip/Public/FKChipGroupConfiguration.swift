import UIKit

/// Layout and behavior for ``FKChipGroup``.
public struct FKChipGroupConfiguration: Sendable, Equatable {
  public var layoutMode: FKChipGroupLayoutMode
  public var itemSpacing: CGFloat
  public var lineSpacing: CGFloat
  public var contentInsets: UIEdgeInsets
  public var chipConfiguration: FKChipConfiguration
  public var chipMode: FKChipMode
  public var overflowBehavior: FKChipGroupOverflowBehavior
  /// When `true` and ``FKChipGroupLayoutMode/horizontalScroll`` is active, selected chips scroll fully into view.
  public var scrollsToSelectedChip: Bool
  /// When horizontal content overflows, narrows the scroll viewport by this amount so a trailing chip peeks at the edge.
  public var horizontalScrollTrailingPeek: CGFloat

  public init(
    layoutMode: FKChipGroupLayoutMode = .flow(),
    itemSpacing: CGFloat = 8,
    lineSpacing: CGFloat = 8,
    contentInsets: UIEdgeInsets = .zero,
    chipConfiguration: FKChipConfiguration = .init(),
    chipMode: FKChipMode = .filter,
    overflowBehavior: FKChipGroupOverflowBehavior = .ignoreTap,
    scrollsToSelectedChip: Bool = true,
    horizontalScrollTrailingPeek: CGFloat = 24
  ) {
    self.layoutMode = layoutMode
    self.itemSpacing = itemSpacing
    self.lineSpacing = lineSpacing
    self.contentInsets = contentInsets
    self.chipConfiguration = chipConfiguration
    self.chipMode = chipMode
    self.overflowBehavior = overflowBehavior
    self.scrollsToSelectedChip = scrollsToSelectedChip
    self.horizontalScrollTrailingPeek = horizontalScrollTrailingPeek
  }
}

extension FKChipGroupConfiguration {
  public static func == (lhs: FKChipGroupConfiguration, rhs: FKChipGroupConfiguration) -> Bool {
    lhs.layoutMode == rhs.layoutMode
      && lhs.itemSpacing == rhs.itemSpacing
      && lhs.lineSpacing == rhs.lineSpacing
      && lhs.chipMode == rhs.chipMode
      && lhs.overflowBehavior == rhs.overflowBehavior
      && lhs.scrollsToSelectedChip == rhs.scrollsToSelectedChip
      && lhs.horizontalScrollTrailingPeek == rhs.horizontalScrollTrailingPeek
  }
}

/// Thread-safe global defaults for ``FKChipGroup``.
public enum FKChipGroupDefaults {
  @MainActor public static var configuration = FKChipGroupConfiguration()
}
