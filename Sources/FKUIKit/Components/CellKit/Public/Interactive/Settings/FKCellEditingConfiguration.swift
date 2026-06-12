import Foundation
public struct FKCellEditingConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var showsReorderControl: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, showsReorderControl: Bool = true, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.showsReorderControl=showsReorderControl
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
