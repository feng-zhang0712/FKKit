import Foundation

// MARK: - Parsing

public extension FKDateTime {
  /// Parses `string` with a custom format pattern.
  static func parse(
    _ string: String,
    format: String,
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime? {
    guard let date = FKDateTimeFormatting.date(
      from: string,
      format: format,
      configuration: configuration
    ) else { return nil }
    return FKDateTime(date, configuration: configuration)
  }

  /// Parses `string` with a ``FKDateTimeFormatPreset``.
  static func parse(
    _ string: String,
    format: FKDateTimeFormatPreset,
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime? {
    parse(string, format: format.rawValue, configuration: configuration)
  }

  /// Parses an ISO-8601 string (with or without fractional seconds / offset).
  static func iso8601(
    _ string: String,
    configuration: FKDateTimeConfiguration = .utc
  ) -> FKDateTime? {
    guard let date = FKDateTimeParsing.iso8601Date(from: string) else { return nil }
    return FKDateTime(date, configuration: configuration)
  }

  /// Tries each format in order and returns the first successful parse.
  static func parse(
    _ string: String,
    formats: [String],
    configuration: FKDateTimeConfiguration = .default
  ) -> FKDateTime? {
    for format in formats {
      if let value = parse(string, format: format, configuration: configuration) {
        return value
      }
    }
    return nil
  }

  /// Returns whether `string` round-trips through the given format.
  static func isValid(
    _ string: String,
    format: String,
    configuration: FKDateTimeConfiguration = .default
  ) -> Bool {
    guard let date = FKDateTimeFormatting.date(
      from: string,
      format: format,
      configuration: configuration
    ) else { return false }
    let rendered = FKDateTimeFormatting.string(
      from: date,
      format: format,
      configuration: configuration
    )
    return rendered == string
  }
}

// MARK: - Formatting

public extension FKDateTime {
  /// Formats with a custom pattern.
  func format(_ format: String) -> String {
    FKDateTimeFormatting.string(from: date, format: format, configuration: configuration)
  }

  /// Formats with a ``FKDateTimeFormatPreset``.
  func format(_ preset: FKDateTimeFormatPreset) -> String {
    format(preset.rawValue)
  }

  /// Formats with Foundation date/time styles.
  func format(
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style
  ) -> String {
    FKDateTimeFormatting.string(
      from: date,
      dateStyle: dateStyle,
      timeStyle: timeStyle,
      configuration: configuration
    )
  }

  /// Formats using a locale-sensitive Unicode template (for example `"yMMMMd"` or `"Hm"`).
  ///
  /// Prefer this over hard-coded patterns when targeting multiple locales — Foundation rearranges
  /// and localizes fields via `DateFormatter.setLocalizedDateFormatFromTemplate(_:)`.
  func format(template: String) -> String {
    FKDateTimeFormatting.string(from: date, template: template, configuration: configuration)
  }

  /// ISO-8601 string in UTC (`yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX` when fractional seconds are enabled).
  func iso8601String(fractionalSeconds: Bool = true) -> String {
    FKDateTimeParsing.iso8601String(from: date, fractionalSeconds: fractionalSeconds)
  }

  /// Unix timestamp in seconds.
  var unixTimestamp: TimeInterval { date.timeIntervalSince1970 }

  /// Unix timestamp in whole milliseconds.
  var unixMilliseconds: Int64 { Int64((date.timeIntervalSince1970 * 1_000).rounded()) }
}
