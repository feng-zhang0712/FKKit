import Foundation

/// Factory for locale-aware Foundation formatters bound to an in-app language.
public struct FKI18nFormatterProvider: Sendable {
  /// Locale used by all formatters created by this provider.
  public let locale: Locale

  /// Creates a formatter provider.
  ///
  /// - Parameter locale: Active in-app locale.
  public init(locale: Locale) {
    self.locale = locale
  }

  /// Creates a number formatter configured for ``locale``.
  ///
  /// - Parameter style: NumberFormatter style.
  /// - Returns: Configured formatter instance.
  public func numberFormatter(style: NumberFormatter.Style = .decimal) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = style
    return formatter
  }

  /// Creates a date formatter configured for ``locale``.
  ///
  /// - Parameters:
  ///   - dateStyle: Date style.
  ///   - timeStyle: Time style.
  /// - Returns: Configured formatter instance.
  public func dateFormatter(
    dateStyle: DateFormatter.Style = .medium,
    timeStyle: DateFormatter.Style = .none
  ) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter
  }

  /// Creates a relative date formatter configured for ``locale``.
  ///
  /// - Parameter unitsStyle: Relative units style.
  /// - Returns: Configured formatter instance.
  public func relativeDateTimeFormatter(
    unitsStyle: RelativeDateTimeFormatter.UnitsStyle = .full
  ) -> RelativeDateTimeFormatter {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = locale
    formatter.unitsStyle = unitsStyle
    return formatter
  }

  /// Creates a measurement formatter configured for ``locale``.
  ///
  /// - Parameter unitStyle: Measurement unit style.
  /// - Returns: Configured formatter instance.
  public func measurementFormatter(unitStyle: MeasurementFormatter.UnitStyle = .medium) -> MeasurementFormatter {
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitStyle = unitStyle
    return formatter
  }
}
