import Foundation

/// Builds ordered language-code candidates for bundle lookup.
public enum FKI18nLocaleMatcher {
  /// Returns progressively broader language codes for resource lookup.
  ///
  /// Example: `zh-Hans-CN` produces `["zh-Hans-CN", "zh-Hans", "zh"]` before appending fallbacks.
  ///
  /// - Parameters:
  ///   - languageCode: Selected BCP-47 language code.
  ///   - additionalFallbacks: Extra codes appended after normalization, such as `en`.
  /// - Returns: De-duplicated candidate codes in lookup order.
  public static func fallbackCandidates(
    for languageCode: String,
    additionalFallbacks: [String] = []
  ) -> [String] {
    var result: [String] = []
    var seen = Set<String>()

    func append(_ code: String) {
      let normalized = code
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "_", with: "-")
      guard !normalized.isEmpty, !seen.contains(normalized) else { return }
      seen.insert(normalized)
      result.append(normalized)
    }

    append(languageCode)

    let components = languageCode
      .replacingOccurrences(of: "_", with: "-")
      .split(separator: "-")
      .map(String.init)

    if components.count > 1 {
      for index in stride(from: components.count - 1, through: 1, by: -1) {
        append(components[0..<index].joined(separator: "-"))
      }
    }

    if let languageOnly = components.first {
      append(languageOnly)
    }

    for fallback in additionalFallbacks {
      append(fallback)
    }

    return result
  }
}
