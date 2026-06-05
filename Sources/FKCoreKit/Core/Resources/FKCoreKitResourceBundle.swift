import Foundation

/// Resolves bundled FKCoreKit assets and localization resources.
public enum FKCoreKitResourceBundle {
  /// Container bundle that hosts `.lproj` directories for FKCoreKit strings.
  public static var container: Bundle {
    #if SWIFT_PACKAGE
    Bundle.module
    #else
    if
      let url = Bundle(for: FKCoreKitBundleToken.self).url(forResource: "FKCoreKit", withExtension: "bundle"),
      let bundle = Bundle(url: url)
    {
      return bundle
    }
    return Bundle(for: FKCoreKitBundleToken.self)
    #endif
  }

  /// Resolves the best `.lproj` bundle for `languageCode` inside ``container``.
  ///
  /// - Parameter languageCode: BCP-47 language code such as `en` or `zh-Hans`.
  /// - Returns: Language-specific bundle, or ``container`` when no match exists.
  public static func localizedBundle(for languageCode: String) -> Bundle {
    FKI18nBundleResolver.bundle(
      for: languageCode,
      in: container,
      fallbackLanguageCodes: [FKI18nRecommendedLanguages.english]
    )
  }
}

private final class FKCoreKitBundleToken: NSObject {}
