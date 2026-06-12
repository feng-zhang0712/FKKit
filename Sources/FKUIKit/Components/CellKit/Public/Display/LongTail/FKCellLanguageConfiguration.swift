import Foundation
public struct FKCellLanguageConfiguration: Sendable, Equatable {
  public var languageName: String; public var nativeName: String?; public var flagIcon: FKCellIconContent?; public var isSelected: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(languageName: String, nativeName: String? = nil, flagIcon: FKCellIconContent? = nil, isSelected: Bool = false,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.languageName=languageName; self.nativeName=nativeName; self.flagIcon=flagIcon; self.isSelected=isSelected
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
