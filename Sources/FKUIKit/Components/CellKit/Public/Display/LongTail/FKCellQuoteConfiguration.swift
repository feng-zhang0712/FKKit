import Foundation
public struct FKCellQuoteConfiguration: Sendable, Equatable {
  public var quoteText: String; public var attribution: String?; public var isItalic: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(quoteText: String, attribution: String? = nil, isItalic: Bool = true, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.quoteText=quoteText; self.attribution=attribution; self.isItalic=isItalic
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
