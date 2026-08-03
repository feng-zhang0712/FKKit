import Foundation

public extension FKDateTime {
  /// Localized relative description against `reference` using the selected style.
  ///
  /// - Parameters:
  ///   - style: Presentation style. Defaults to ``FKDateTimeRelativeStyle/chat`` (WeChat message timestamps).
  ///     Prefer ``FKDateTimeRelativeStyle/standard`` or ``fromNow(style:)`` for conversational “ago” copy.
  ///   - reference: Comparison instant (default: now). Yesterday / tomorrow buckets are relative to this value.
  /// - Returns: Localized human-readable text.
  func relative(
    style: FKDateTimeRelativeStyle = .chat,
    reference: Date = Date()
  ) -> String {
    FKDateTimeRelativeEngine.string(
      for: date,
      reference: reference,
      style: style,
      configuration: configuration
    )
  }

  /// Relative description of this instant against the current time (Moment-style `fromNow`).
  ///
  /// Defaults to ``FKDateTimeRelativeStyle/standard`` (unlike ``relative(style:reference:)``, which defaults to `.chat`).
  func fromNow(style: FKDateTimeRelativeStyle = .standard) -> String {
    relative(style: style, reference: Date())
  }

  /// Relative description of this instant against `other` (Moment-style `from`).
  ///
  /// Equivalent to `relative(style:reference: other.date)`.
  func from(_ other: FKDateTime, style: FKDateTimeRelativeStyle = .standard) -> String {
    relative(style: style, reference: other.date)
  }
}
