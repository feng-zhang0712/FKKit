import Foundation

/// Keys for ``Notification/Name/fk_copyChipDidCopy`` `userInfo`.
public enum FKCopyChipNotificationKeys {
  /// The string written to the pasteboard (`String`).
  public static let copiedText = "FKCopyChipNotificationKeys.copiedText"
}

public extension Notification.Name {
  /// Posted after ``FKCopyChip`` successfully writes to the pasteboard.
  static let fk_copyChipDidCopy = Notification.Name("fk.copyChip.didCopy")
}
