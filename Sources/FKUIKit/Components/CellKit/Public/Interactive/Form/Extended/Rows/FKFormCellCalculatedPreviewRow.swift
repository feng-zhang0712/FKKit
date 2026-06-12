import Foundation

/// ListKit-friendly row model for ``FKFormCellCalculatedPreviewCell``.
public struct FKFormCellCalculatedPreviewRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellCalculatedPreviewConfiguration
  public var text: String
  public var previewText: String

  public init(
    id: String,
    configuration: FKFormCellCalculatedPreviewConfiguration,
    text: String = "",
    previewText: String = ""
  ) {
    self.id = id
    self.configuration = configuration
    self.text = text
    self.previewText = previewText
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
