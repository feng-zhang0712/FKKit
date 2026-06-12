import UIKit

/// Builds attributed strings with query highlighting for search result rows (D-66).
public enum FKCellSearchHighlight {
  /// Returns an attributed string highlighting all case-insensitive occurrences of `query` in `text`.
  public static func attributedString(
    text: String,
    query: String,
    baseFont: UIFont = .preferredFont(forTextStyle: .body),
    baseColor: UIColor = .label,
    highlightFont: UIFont? = nil,
    highlightColor: UIColor = .systemBlue
  ) -> NSAttributedString {
    let attributed = NSMutableAttributedString(
      string: text,
      attributes: [
        .font: baseFont,
        .foregroundColor: baseColor,
      ]
    )
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else { return attributed }

    let highlightFont = highlightFont ?? baseFont
    let options: NSString.CompareOptions = [.caseInsensitive]
    var searchRange = NSRange(location: 0, length: (text as NSString).length)

    while searchRange.location < searchRange.length {
      let found = (text as NSString).range(of: trimmedQuery, options: options, range: searchRange)
      if found.location == NSNotFound { break }
      attributed.addAttributes(
        [
          .font: highlightFont,
          .foregroundColor: highlightColor,
        ],
        range: found
      )
      searchRange.location = found.location + found.length
      searchRange.length = (text as NSString).length - searchRange.location
    }

    return attributed
  }
}
