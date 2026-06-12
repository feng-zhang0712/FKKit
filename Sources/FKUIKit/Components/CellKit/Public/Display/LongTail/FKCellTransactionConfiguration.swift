import Foundation
public enum FKCellTransactionKind: Sendable, Equatable { case credit, debit, neutral }
public struct FKCellTransactionConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var amountText: String; public var kind: FKCellTransactionKind
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, amountText: String, kind: FKCellTransactionKind = .neutral,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.amountText=amountText; self.kind=kind
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
