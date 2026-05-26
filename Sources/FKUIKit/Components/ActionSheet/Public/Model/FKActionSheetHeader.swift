import Foundation

/// Optional title and message shown above action groups.
public struct FKActionSheetHeader: Equatable, Sendable {
  /// Bold title centered above the groups.
  public var title: String?
  /// Secondary message below the title.
  public var message: String?

  /// Creates a header block.
  public init(title: String? = nil, message: String? = nil) {
    self.title = title
    self.message = message
  }

  /// Whether any text is configured.
  public var isEmpty: Bool {
    let titleEmpty = title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    let messageEmpty = message?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    return titleEmpty && messageEmpty
  }
}
