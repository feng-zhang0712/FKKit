import Foundation
public enum FKCellCheckboxPlacement: Sendable, Equatable { case leading, trailing }
public struct FKCellCheckboxConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var isChecked: Bool; public var placement: FKCellCheckboxPlacement
  public var togglesOnRowTap: Bool; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, isChecked: Bool = false, placement: FKCellCheckboxPlacement = .leading,
    togglesOnRowTap: Bool = true, isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.isChecked=isChecked; self.placement=placement
    self.togglesOnRowTap=togglesOnRowTap; self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
