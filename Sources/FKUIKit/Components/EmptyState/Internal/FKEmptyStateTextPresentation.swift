import FKCoreKit
import UIKit

struct FKEmptyStatePresentedText: Equatable {
  let display: String
  let accessibility: String
  let wasTruncated: Bool
}

enum FKEmptyStateTextPresentation {
  static func presentedText(
    _ raw: String?,
    maxCharacters: Int?,
    suffix: String
  ) -> FKEmptyStatePresentedText? {
    guard let raw else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let display = truncated(trimmed, maxCharacters: maxCharacters, suffix: suffix)
    return FKEmptyStatePresentedText(
      display: display,
      accessibility: trimmed,
      wasTruncated: display != trimmed
    )
  }

  static func resolvedMaxLines(_ explicit: Int?, fallback: Int?) -> Int? {
    explicit ?? fallback
  }

  static func labelNumberOfLines(for maxLines: Int?) -> Int {
    guard let maxLines, maxLines > 0 else { return 0 }
    return maxLines
  }

  private static func truncated(_ text: String, maxCharacters: Int?, suffix: String) -> String {
    guard let maxCharacters, maxCharacters > 0, text.count > maxCharacters else { return text }
    let suffixCount = suffix.count
    let keep = max(0, maxCharacters - suffixCount)
    guard keep > 0 else { return suffix }
    return text.fk_limitedPrefix(keep) + suffix
  }
}
