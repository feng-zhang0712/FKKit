import Foundation

/// Configuration for ``FKCellAlertActionCell`` (D-09).
public struct FKCellAlertActionConfiguration: Sendable, Equatable {
  public var title: String
  public var warningSymbolName: String?
  public var body: String
  public var primaryAction: FKCellActionLink
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    title: String,
    warningSymbolName: String? = "exclamationmark.triangle.fill",
    body: String,
    primaryAction: FKCellActionLink,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.title = title
    self.warningSymbolName = warningSymbolName
    self.body = body
    self.primaryAction = primaryAction
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
