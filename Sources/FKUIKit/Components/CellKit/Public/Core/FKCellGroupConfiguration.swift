import UIKit

/// Position of a row inside an inset grouped section card.
public enum FKCellGroupPosition: Sendable, Equatable {
  case single
  case first
  case middle
  case last
}

/// Visual grouping metadata for inset grouped list rows (S-03).
public struct FKCellGroupConfiguration: @unchecked Sendable, Equatable {
  public var cornerRadius: CGFloat
  public var backgroundColor: UIColor
  public var positionInSection: FKCellGroupPosition

  /// Creates a group configuration.
  public init(
    cornerRadius: CGFloat,
    backgroundColor: UIColor,
    positionInSection: FKCellGroupPosition
  ) {
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.positionInSection = positionInSection
  }

  /// Convenience builder using appearance defaults.
  @MainActor
  public static func insetGrouped(
    position: FKCellGroupPosition,
    appearance: FKCellAppearanceConfiguration = .default
  ) -> FKCellGroupConfiguration {
    FKCellGroupConfiguration(
      cornerRadius: appearance.cornerRadius,
      backgroundColor: appearance.cellBackgroundColor,
      positionInSection: position
    )
  }
}

extension FKCellGroupConfiguration {
  public static func == (lhs: FKCellGroupConfiguration, rhs: FKCellGroupConfiguration) -> Bool {
    lhs.cornerRadius == rhs.cornerRadius
      && lhs.backgroundColor.isEqual(rhs.backgroundColor)
      && lhs.positionInSection == rhs.positionInSection
  }
}
