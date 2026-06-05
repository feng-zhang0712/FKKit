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

  /// Maps region-style Chinese codes to script-based `.lproj` folder names used by FKKit.
  ///
  /// FKKit stores Chinese as `zh-Hans.lproj` / `zh-Hant.lproj`, while iOS often reports
  /// `zh-CN`, `zh-TW`, etc. Other languages use language-level folders (`ja`, `en`, …) and
  /// are covered by ``fallbackCandidates(for:additionalFallbacks:)`` without extra aliases.
  private static let languageAliases: [String: String] = [
    "zh-CN": "zh-Hans",
    "zh-Hans-CN": "zh-Hans",
    "zh-SG": "zh-Hans",
    "zh-TW": "zh-Hant",
    "zh-HK": "zh-Hant",
    "zh-MO": "zh-Hant",
    "zh-Hant-TW": "zh-Hant",
    "zh-Hant-HK": "zh-Hant",
  ]

  /// Normalizes a BCP-47 code and maps known aliases to FKKit resource folder names.
  ///
  /// - Parameter code: Input language code such as `zh-CN` or `zh-Hans`.
  /// - Returns: Canonical code used for persistence and `.lproj` lookup.
  public static func canonicalize(_ code: String) -> String {
    let normalized = normalize(code)
    return languageAliases[normalized] ?? normalized
  }

  /// De-duplicates language codes while preserving first-seen order.
  public static func uniqueLanguageCodes(_ codes: [String]) -> [String] {
    var result: [String] = []
    var seen = Set<String>()
    for code in codes {
      let normalized = normalize(code)
      guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
      seen.insert(normalized)
      result.append(normalized)
    }
    return result
  }

  /// Picks the best supported language for the user's preferred locales.
  ///
  /// - Parameters:
  ///   - preferredLanguageCodes: Ordered preferred codes (for example `Bundle.main.preferredLocalizations`).
  ///   - supportedLanguageCodes: Languages exposed by the host app or library configuration.
  ///   - fallback: Code used when no preferred locale matches.
  /// - Returns: First matching supported code, or ``fallback`` when none match.
  public static func bestSupportedLanguage(
    preferredLanguageCodes: [String],
    supportedLanguageCodes: [String],
    fallback: String
  ) -> String {
    guard !supportedLanguageCodes.isEmpty else { return normalize(fallback) }

    let supported = Set(supportedLanguageCodes.map(normalize))

    for preferred in preferredLanguageCodes {
      let normalizedPreferred = normalize(preferred)
      for candidate in fallbackCandidates(for: normalizedPreferred) {
        let resolved = canonicalize(candidate)
        if supported.contains(resolved) {
          return resolved
        }
      }
    }

    let normalizedFallback = normalize(fallback)
    if supported.contains(normalizedFallback) {
      return normalizedFallback
    }
    return supportedLanguageCodes[0]
  }

  private static func normalize(_ code: String) -> String {
    code
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "_", with: "-")
  }
}
