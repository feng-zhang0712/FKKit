import Foundation

public extension String {
  /// Localizes the receiver using ``FKI18nManager/shared``.
  ///
  /// - Parameters:
  ///   - table: Optional strings table name.
  ///   - i18n: Localization provider. Defaults to the shared manager.
  /// - Returns: Localized string value.
  func fk_localized(table: String? = nil, using i18n: FKI18nLocalizing = FKI18nManager.shared) -> String {
    i18n.localized(self, table: table)
  }

  /// Localizes the receiver and interpolates `{token}` placeholders.
  ///
  /// - Parameters:
  ///   - variables: Placeholder map keyed by token name without braces.
  ///   - table: Optional strings table name.
  ///   - i18n: Localization provider. Defaults to the shared manager.
  /// - Returns: Interpolated localized string.
  func fk_localized(
    variables: [String: String],
    table: String? = nil,
    using i18n: FKI18nLocalizing = FKI18nManager.shared
  ) -> String {
    i18n.localized(self, table: table, variables: variables)
  }
}

public extension FKI18nKey {
  /// Localizes the receiver using ``FKI18nManager/shared``.
  ///
  /// - Parameters:
  ///   - table: Optional strings table name.
  ///   - i18n: Localization provider. Defaults to the shared manager.
  /// - Returns: Localized string value.
  func fk_localized(table: String? = nil, using i18n: FKI18nLocalizing = FKI18nManager.shared) -> String {
    i18n.localized(self, table: table)
  }
}
