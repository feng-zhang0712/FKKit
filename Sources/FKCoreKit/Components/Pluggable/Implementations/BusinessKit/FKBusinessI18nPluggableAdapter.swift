import Foundation

/// Bridges ``FKBusinessLocalizing`` to Pluggable ``FKLocalizing``.
public final class FKBusinessI18nPluggableAdapter: FKLocalizing, @unchecked Sendable {
  /// Underlying BusinessKit localization manager.
  private let localizing: FKBusinessLocalizing

  /// Creates an adapter over a BusinessKit localizing implementation.
  ///
  /// - Parameter localizing: BusinessKit localizer (default shared instance).
  public init(localizing: FKBusinessLocalizing = FKBusinessKit.shared.i18n) {
    self.localizing = localizing
  }

  /// Current selected language code.
  public var currentLanguageCode: String {
    localizing.currentLanguageCode
  }

  /// Updates current language and notifies observers.
  public func setLanguageCode(_ code: String) {
    localizing.setLanguageCode(code)
  }

  /// Resolves localized text from the active language bundle.
  public func localized(_ key: String, table: String?) -> String {
    localizing.localized(key, table: table)
  }

  /// Observes language changes and returns a Pluggable cancellation token.
  @discardableResult
  public func observeLanguageChange(
    _ handler: @escaping @Sendable (String) -> Void
  ) -> FKPluggableObservationToken {
    let token = localizing.observeLanguageChange(handler)
    return FKPluggableObservationToken {
      token.invalidate()
    }
  }
}
