import Foundation

/// Configuration for ``FKCellRegulatoryCell`` (D-15).
public struct FKCellRegulatoryConfiguration: Sendable, Equatable {
  public var regionTitle: String
  public var contentBlocks: [FKCellRegulatoryBlock]
  public var footerMetadata: String?
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a regulatory disclosure row configuration.
  public init(
    regionTitle: String,
    contentBlocks: [FKCellRegulatoryBlock],
    footerMetadata: String? = nil,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.regionTitle = regionTitle
    self.contentBlocks = contentBlocks
    self.footerMetadata = footerMetadata
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
