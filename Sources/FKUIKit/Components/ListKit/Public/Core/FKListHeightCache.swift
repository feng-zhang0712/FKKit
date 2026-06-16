import UIKit

/// Width-keyed row height cache for dynamic feed lists.
@MainActor
public final class FKListHeightCache {
  private struct Key: Hashable {
    let itemID: FKListItemID
    let widthBucket: Int
  }

  private var storage: [Key: CGFloat] = [:]

  public init() {}

  /// Returns a cached height when width matches a prior measurement.
  public func height(for itemID: FKListItemID, width: CGFloat) -> CGFloat? {
    storage[Key(itemID: itemID, widthBucket: widthBucket(for: width))]
  }

  /// Stores a measured row height for `itemID` at `width`.
  public func setHeight(_ height: CGFloat, for itemID: FKListItemID, width: CGFloat) {
    storage[Key(itemID: itemID, widthBucket: widthBucket(for: width))] = max(1, height)
  }

  /// Drops cached heights for one item (e.g. after text expansion).
  public func invalidate(itemID: FKListItemID) {
    storage = storage.filter { $0.key.itemID != itemID }
  }

  /// Clears all cached heights.
  public func invalidateAll() {
    storage.removeAll()
  }

  /// Measures single-style plain text height for table/collection width budgeting.
  public static func measuredTextHeight(
    _ text: String,
    font: UIFont,
    width: CGFloat,
    insets: UIEdgeInsets = .zero,
    maxLines: Int? = nil
  ) -> CGFloat {
    guard width > 0, !text.isEmpty else { return insets.top + insets.bottom }
    let textWidth = max(1, width - insets.left - insets.right)
    var attributes: [NSAttributedString.Key: Any] = [.font: font]
    if let maxLines, maxLines > 0 {
      let paragraph = NSMutableParagraphStyle()
      paragraph.lineBreakMode = .byTruncatingTail
      attributes[.paragraphStyle] = paragraph
    }
    let bounding = (text as NSString).boundingRect(
      with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: attributes,
      context: nil
    )
    var height = ceil(bounding.height)
    if let maxLines, maxLines > 0 {
      height = min(height, font.lineHeight * CGFloat(maxLines) + font.leading)
    }
    return height + insets.top + insets.bottom
  }

  private func widthBucket(for width: CGFloat) -> Int {
    Int((width * 2).rounded())
  }
}
