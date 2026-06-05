import Foundation

extension FKI18nManager: FKLocalizing {
  public func localized(_ key: String, table: String?) -> String {
    localized(key, table: table, bundle: nil)
  }

  public func observeLanguageChange(
    _ handler: @escaping @Sendable (String) -> Void
  ) -> FKPluggableObservationToken {
    let token = observeLanguageChange { language in
      handler(language.code)
    }
    return FKPluggableObservationToken {
      token.invalidate()
    }
  }
}

extension FKI18nDictionaryLocalizer: FKLocalizing {
  public func localized(_ key: String, table: String?) -> String {
    localized(key, table: table, bundle: nil)
  }

  public func observeLanguageChange(
    _ handler: @escaping @Sendable (String) -> Void
  ) -> FKPluggableObservationToken {
    let token = observeLanguageChange { language in
      handler(language.code)
    }
    return FKPluggableObservationToken {
      token.invalidate()
    }
  }
}
