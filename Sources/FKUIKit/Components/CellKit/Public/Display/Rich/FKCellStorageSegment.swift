import UIKit

/// Named storage segment with proportional fill for ``FKCellStorageSummaryCell`` (D-13).
public struct FKCellStorageSegment: @unchecked Sendable, Equatable {
  public var name: String
  public var color: UIColor
  public var proportion: Double

  /// Creates a storage segment legend entry.
  public init(name: String, color: UIColor, proportion: Double) {
    self.name = name
    self.color = color
    self.proportion = max(0, proportion)
  }
}

extension FKCellStorageSegment {
  public static func == (lhs: FKCellStorageSegment, rhs: FKCellStorageSegment) -> Bool {
    lhs.name == rhs.name && lhs.color == rhs.color && lhs.proportion == rhs.proportion
  }
}
