import Foundation

/// Configuration for ``FKFormCellEmojiPickerCell`` (X-66).
public struct FKFormCellEmojiPickerConfiguration: Sendable, Equatable {
  public var label: String?
  public var emojis: [String]
  public var selectedEmoji: String?
  public var isEnabled: Bool

  /// Creates a horizontal emoji picker configuration.
  public init(
    label: String? = nil,
    emojis: [String] = ["👍", "❤️", "😂", "😮", "😢", "🙏"],
    selectedEmoji: String? = nil,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.emojis = emojis
    self.selectedEmoji = selectedEmoji
    self.isEnabled = isEnabled
  }
}
