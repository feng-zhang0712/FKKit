import Foundation

/// Step state for ``FKCellStepListCell`` (D-50).
public enum FKCellStepState: Sendable, Equatable {
  case pending
  case completed
  case current
}

/// Configuration for ``FKCellStepListCell`` (D-50).
public struct FKCellStepListConfiguration: Sendable, Equatable {
  public var stepNumber: Int
  public var title: String
  public var detail: String?
  public var state: FKCellStepState
  public var statusText: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    stepNumber: Int,
    title: String,
    detail: String? = nil,
    state: FKCellStepState = .pending,
    statusText: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.stepNumber = stepNumber
    self.title = title
    self.detail = detail
    self.state = state
    self.statusText = statusText
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
