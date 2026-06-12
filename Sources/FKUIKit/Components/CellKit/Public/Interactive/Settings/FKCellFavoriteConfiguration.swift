import Foundation
public struct FKCellFavoriteConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var isFavorite: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, isFavorite: Bool = false, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.isFavorite=isFavorite; self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
