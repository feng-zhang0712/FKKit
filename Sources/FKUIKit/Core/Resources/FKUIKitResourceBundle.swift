import FKCoreKit
import UIKit

/// Resolves bundled FKUIKit assets (Symbol Image sets in ``Assets.xcassets``).
enum FKUIKitResourceBundle {
  /// Asset names for Material-derived custom symbol images shipped with FKUIKit.
  enum SymbolName: String, Sendable {
    case check
    case close
    case radioChecked = "radio_checked"
    case radioUnchecked = "radio_unchecked"
  }

  /// Bundle that contains ``Assets.xcassets`` for SPM and CocoaPods consumers.
  static var bundle: Bundle {
    #if SWIFT_PACKAGE
    Bundle.module
    #else
    if
      let url = Bundle(for: FKUIKitBundleToken.self).url(forResource: "FKUIKit", withExtension: "bundle"),
      let bundle = Bundle(url: url)
    {
      return bundle
    }
    return Bundle(for: FKUIKitBundleToken.self)
    #endif
  }

  /// Resolves the best `.lproj` bundle for `languageCode` inside ``bundle``.
  ///
  /// - Parameter languageCode: BCP-47 language code such as `en` or `zh-Hans`.
  /// - Returns: Language-specific bundle, or ``bundle`` when no match exists.
  static func localizedBundle(for languageCode: String) -> Bundle {
    FKI18nBundleResolver.bundle(
      for: languageCode,
      in: bundle,
      fallbackLanguageCodes: [FKI18nRecommendedLanguages.english]
    )
  }

  /// Loads a custom symbol image by asset name.
  ///
  /// - Parameter name: Symbol set name in ``Assets.xcassets``.
  /// - Returns: A symbol image when the asset is present in the module bundle.
  static func symbol(named name: SymbolName, configuration: UIImage.SymbolConfiguration? = nil) -> UIImage? {
    guard let image = UIImage(named: name.rawValue, in: bundle, with: nil) else { return nil }
    guard let configuration else { return image }
    return image.applyingSymbolConfiguration(configuration) ?? image
  }
}

private final class FKUIKitBundleToken: NSObject {}
