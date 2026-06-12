import Foundation
public struct FKCellIndentedConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var indentLevel: Int
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, indentLevel: Int = 1, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.indentLevel=indentLevel
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
