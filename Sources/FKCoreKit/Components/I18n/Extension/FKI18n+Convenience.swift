import Foundation

/// Convenience accessors for ``FKI18nManager``.
public extension FKCoreKit {
  /// Shared in-app localization manager.
  static var i18n: FKI18nManager { FKI18nManager.shared }
}

/// Resolves a localized string through ``FKI18nManager/shared``.
///
/// - Parameters:
///   - key: Localization key.
///   - table: Optional strings table name.
/// - Returns: Localized string value.
public func FKI18nString(_ key: String, table: String? = nil) -> String {
  FKI18nManager.shared.localized(key, table: table)
}

/// Resolves a typed localization key through ``FKI18nManager/shared``.
///
/// - Parameters:
///   - key: Typed localization key.
///   - table: Optional strings table name.
/// - Returns: Localized string value.
public func FKI18nString(_ key: FKI18nKey, table: String? = nil) -> String {
  FKI18nManager.shared.localized(key, table: table)
}
