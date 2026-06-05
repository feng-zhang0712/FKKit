import Foundation

/// Runtime configuration for ``FKI18nManager``.
public struct FKI18nConfiguration: Sendable {
  /// Fallback language code used on first launch and when bundle lookup fails.
  public var defaultLanguageCode: String

  /// Ordered list of language codes exposed in in-app language pickers.
  public var supportedLanguageCodes: [String]

  /// Additional fallback codes appended after locale-specific candidates during bundle lookup.
  public var fallbackLanguageCodes: [String]

  /// Container bundle that hosts `.lproj` directories.
  public var bundle: Bundle

  /// Whether the selected language is persisted across launches.
  public var persistSelection: Bool

  /// UserDefaults key for persisted language code.
  public var storageKey: String

  /// When `true`, ``FKI18nManager/setLanguageCode(_:)`` ignores unsupported codes.
  public var enforceSupportedLanguages: Bool

  /// Creates an i18n configuration.
  ///
  /// - Parameters:
  ///   - defaultLanguageCode: Initial and fallback language code.
  ///   - supportedLanguageCodes: Languages available for in-app switching.
  ///   - fallbackLanguageCodes: Extra bundle lookup fallbacks after locale normalization.
  ///   - bundle: Bundle containing localization resources.
  ///   - persistSelection: Whether user selection is written to UserDefaults.
  ///   - storageKey: Key used to store selected language code.
  ///   - enforceSupportedLanguages: Restrict switching to ``supportedLanguageCodes``.
  public init(
    defaultLanguageCode: String = "en",
    supportedLanguageCodes: [String] = ["en"],
    fallbackLanguageCodes: [String] = [],
    bundle: Bundle = .main,
    persistSelection: Bool = true,
    storageKey: String = "com.fkkit.i18n.language",
    enforceSupportedLanguages: Bool = true
  ) {
    self.defaultLanguageCode = defaultLanguageCode
    self.supportedLanguageCodes = supportedLanguageCodes
    self.fallbackLanguageCodes = fallbackLanguageCodes
    self.bundle = bundle
    self.persistSelection = persistSelection
    self.storageKey = storageKey
    self.enforceSupportedLanguages = enforceSupportedLanguages
  }

  /// Default configuration using `Bundle.main` and English as fallback.
  public static let `default` = FKI18nConfiguration()
}

extension FKI18nConfiguration: Equatable {
  public static func == (lhs: FKI18nConfiguration, rhs: FKI18nConfiguration) -> Bool {
    lhs.defaultLanguageCode == rhs.defaultLanguageCode
      && lhs.supportedLanguageCodes == rhs.supportedLanguageCodes
      && lhs.fallbackLanguageCodes == rhs.fallbackLanguageCodes
      && lhs.bundle.bundlePath == rhs.bundle.bundlePath
      && lhs.persistSelection == rhs.persistSelection
      && lhs.storageKey == rhs.storageKey
      && lhs.enforceSupportedLanguages == rhs.enforceSupportedLanguages
  }
}
