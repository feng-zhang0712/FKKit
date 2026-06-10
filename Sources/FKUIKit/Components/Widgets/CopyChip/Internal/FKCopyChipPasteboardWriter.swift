import UIKit

/// Writes plain text to the general pasteboard with optional expiration metadata.
enum FKCopyChipPasteboardWriter {
  static func copy(_ text: String, expiration: Date?) {
    guard !text.isEmpty else { return }
    if let expiration {
      UIPasteboard.general.setItems(
        [[UIPasteboard.typeAutomatic: text]],
        options: [.expirationDate: expiration]
      )
    } else {
      UIPasteboard.general.string = text
    }
  }
}
