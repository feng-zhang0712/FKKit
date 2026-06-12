import Foundation

/// Configuration for ``FKCellProductCell`` (D-28).
public struct FKCellProductConfiguration: Sendable, Equatable {
  public var image: FKCellImageContent
  public var title: String
  public var specText: String?
  public var price: String
  public var quantityText: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    image: FKCellImageContent = FKCellImageContent(),
    title: String,
    specText: String? = nil,
    price: String,
    quantityText: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.image = image
    self.title = title
    self.specText = specText
    self.price = price
    self.quantityText = quantityText
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
