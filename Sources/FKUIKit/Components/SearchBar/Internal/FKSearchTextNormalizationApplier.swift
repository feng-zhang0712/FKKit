import Foundation

enum FKSearchTextNormalizationApplier {
  static func apply(_ normalization: FKSearchTextNormalization, to text: String) -> String {
    switch normalization {
    case .none:
      return text
    case .trimWhitespaceAndNewlines:
      return text.trimmingCharacters(in: .whitespacesAndNewlines)
    case .collapseInternalWhitespace:
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
    case let .maxLength(limit):
      guard limit >= 0 else { return text }
      return String(text.prefix(limit))
    }
  }
}
