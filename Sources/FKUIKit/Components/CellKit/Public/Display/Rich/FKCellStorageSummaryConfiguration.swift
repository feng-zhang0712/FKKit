import Foundation

/// Configuration for ``FKCellStorageSummaryCell`` (D-13).
public struct FKCellStorageSummaryConfiguration: Sendable, Equatable {
  public var title: String
  public var usageText: String
  public var segments: [FKCellStorageSegment]
  public var progress: Double
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a storage summary card configuration.
  public init(
    title: String,
    usageText: String,
    segments: [FKCellStorageSegment] = [],
    progress: Double = 0,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.title = title
    self.usageText = usageText
    self.segments = segments
    self.progress = progress
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
