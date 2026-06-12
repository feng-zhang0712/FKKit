import Foundation

/// ListKit-friendly row model for ``FKFormCellEmojiPickerCell``.
public struct FKFormCellEmojiPickerRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellEmojiPickerConfiguration
  public var selectedEmoji: String?

  public init(
    id: String,
    configuration: FKFormCellEmojiPickerConfiguration,
    selectedEmoji: String? = nil
  ) {
    self.id = id
    self.configuration = configuration
    self.selectedEmoji = selectedEmoji
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
