import Foundation
public struct FKCellReminderConfiguration: Sendable, Equatable {
  public var title: String; public var timeText: String
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, timeText: String, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.timeText=timeText; self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
