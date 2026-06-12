import Foundation

/// Node state for ``FKCellTimelineNodeCell`` vertical axis (D-32).
public enum FKCellTimelineNodeState: Sendable, Equatable {
  case completed
  case current
  case upcoming
  case failed
}

/// Configuration for ``FKCellTimelineNodeCell`` (D-32).
public struct FKCellTimelineNodeConfiguration: Sendable, Equatable {
  public var state: FKCellTimelineNodeState
  public var title: String
  public var subtitle: String?
  public var timestamp: String?
  public var isFirst: Bool
  public var isLast: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a timeline node row configuration.
  public init(
    state: FKCellTimelineNodeState,
    title: String,
    subtitle: String? = nil,
    timestamp: String? = nil,
    isFirst: Bool = false,
    isLast: Bool = false,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = false
  ) {
    self.state = state
    self.title = title
    self.subtitle = subtitle
    self.timestamp = timestamp
    self.isFirst = isFirst
    self.isLast = isLast
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
