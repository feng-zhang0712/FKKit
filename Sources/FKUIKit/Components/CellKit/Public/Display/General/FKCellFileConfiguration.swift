import Foundation

/// Cloud sync state for file rows (D-45).
public enum FKCellFileCloudState: Sendable, Equatable {
  case localOnly
  case synced
  case uploading
}

/// Configuration for ``FKCellFileCell`` (D-45).
public struct FKCellFileConfiguration: Sendable, Equatable {
  public var fileIcon: FKCellIconContent
  public var fileName: String
  public var meta: String?
  public var cloudState: FKCellFileCloudState?
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    fileIcon: FKCellIconContent = FKCellIconContent(symbolName: "doc.fill"),
    fileName: String,
    meta: String? = nil,
    cloudState: FKCellFileCloudState? = nil,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.fileIcon = fileIcon
    self.fileName = fileName
    self.meta = meta
    self.cloudState = cloudState
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
