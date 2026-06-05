import Foundation

/// Resolves language-specific bundles from a container bundle.
public enum FKI18nBundleResolver {
  /// Locates the best matching `.lproj` bundle for `languageCode`.
  ///
  /// - Parameters:
  ///   - languageCode: Selected BCP-47 language code.
  ///   - container: Bundle that hosts `.lproj` directories.
  ///   - fallbackLanguageCodes: Extra lookup fallbacks appended after locale normalization.
  /// - Returns: Matching localization bundle, or `container` when no `.lproj` matches.
  public static func bundle(
    for languageCode: String,
    in container: Bundle,
    fallbackLanguageCodes: [String] = []
  ) -> Bundle {
    let candidates = FKI18nLocaleMatcher.fallbackCandidates(
      for: languageCode,
      additionalFallbacks: fallbackLanguageCodes
    )

    for code in candidates {
      guard let path = container.path(forResource: code, ofType: "lproj"),
            let bundle = Bundle(path: path) else {
        continue
      }
      return bundle
    }

    return container
  }
}
