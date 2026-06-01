import UIKit

/// Effective layout hints after ``FKTabBar`` resolves trait environment, overflow rules, and strip geometry.
///
/// Read via ``FKTabBar/resolvedLayoutHintsForCurrentEnvironment()`` when static configuration knobs
/// interact (for example ``FKTabBarLayoutConfiguration/titleOverflowMode`` × ``largeTextLayoutStrategy`` × ``nonScrollableOverflowPolicy``).
public struct FKTabBarResolvedLayoutHints: Equatable, Sendable {
  /// Resolved title overflow and line-count policy.
  public var titlePresentation: FKTabBarResolvedTitlePresentation
  /// Bottom safe-area behavior from layout configuration.
  public var bottomSafeAreaBehavior: FKTabBarBottomSafeAreaBehavior
  /// `true` when non-fill content alignment is distributing extra horizontal space.
  public var isContentAlignmentActive: Bool
  /// `true` when per-index ``FKTabBarCustomization/customSpacing(after:context:)`` gaps are active.
  public var usesPerIndexCustomSpacing: Bool

  /// Creates a resolved layout hints snapshot.
  public init(
    titlePresentation: FKTabBarResolvedTitlePresentation,
    bottomSafeAreaBehavior: FKTabBarBottomSafeAreaBehavior,
    isContentAlignmentActive: Bool,
    usesPerIndexCustomSpacing: Bool
  ) {
    self.titlePresentation = titlePresentation
    self.bottomSafeAreaBehavior = bottomSafeAreaBehavior
    self.isContentAlignmentActive = isContentAlignmentActive
    self.usesPerIndexCustomSpacing = usesPerIndexCustomSpacing
  }
}
