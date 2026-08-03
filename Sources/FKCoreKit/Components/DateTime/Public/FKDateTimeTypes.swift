import Foundation

/// Calendar unit used by ``FKDateTime`` arithmetic, boundaries, and diffs.
public enum FKDateTimeUnit: String, Sendable, CaseIterable, Equatable {
  case year
  case month
  case week
  case day
  case hour
  case minute
  case second

  /// Matching `Calendar.Component` for Foundation APIs.
  public var calendarComponent: Calendar.Component {
    switch self {
    case .year: return .year
    case .month: return .month
    case .week: return .weekOfYear
    case .day: return .day
    case .hour: return .hour
    case .minute: return .minute
    case .second: return .second
    }
  }
}

/// Common absolute format presets (strftime-style tokens via `DateFormatter`).
public enum FKDateTimeFormatPreset: String, Sendable, CaseIterable, Equatable {
  /// `yyyy-MM-dd`
  case date = "yyyy-MM-dd"
  /// `HH:mm:ss`
  case time = "HH:mm:ss"
  /// `HH:mm`
  case timeShort = "HH:mm"
  /// `yyyy-MM-dd HH:mm:ss`
  case dateTime = "yyyy-MM-dd HH:mm:ss"
  /// `yyyy-MM-dd HH:mm`
  case dateTimeShort = "yyyy-MM-dd HH:mm"
  /// `MM-dd`
  case monthDay = "MM-dd"
  /// `yyyy-MM`
  case yearMonth = "yyyy-MM"
  /// `yyyy-MM-dd'T'HH:mm:ss`
  case iso8601Local = "yyyy-MM-dd'T'HH:mm:ss"
  /// `yyyy-MM-dd'T'HH:mm:ssZ` (RFC 822 zone)
  case iso8601Offset = "yyyy-MM-dd'T'HH:mm:ssZ"
}

/// Relative / humanized presentation style.
///
/// Prefer ``chat`` for messaging timestamps and ``feed`` for social timelines — both follow
/// WeChat-like progressive absolute fallbacks with localized copy.
public enum FKDateTimeRelativeStyle: Sendable, Equatable {
  /// WeChat conversation timestamps:
  /// same day → `HH:mm`; yesterday → `Yesterday HH:mm`; within 7 days → weekday + time;
  /// same year → `MM-dd HH:mm`; else → `yyyy-MM-dd HH:mm`.
  case chat

  /// WeChat Moments / feed style:
  /// just now → minutes → hours → yesterday → `MM-dd` / `yyyy-MM-dd`.
  case feed

  /// Conversational past/future relative text (`Just now`, `3 minutes ago`, `In 2 hours`, …)
  /// with absolute date fallback for older values.
  case standard

  /// Locale-aware `RelativeDateTimeFormatter` (system phrasing).
  case system(RelativeDateTimeFormatter.UnitsStyle)
}

/// Signed calendar difference between two ``FKDateTime`` values.
public struct FKDateTimeDiff: Sendable, Equatable {
  /// Raw Foundation components (may be negative when the receiver is earlier than the other date).
  public let components: DateComponents

  /// Total elapsed seconds between the two absolute instants (other − self when produced by `diff(to:)`).
  public let totalSeconds: TimeInterval

  /// Year component, or `0` when absent.
  public var years: Int { components.year ?? 0 }

  /// Month component, or `0` when absent.
  public var months: Int { components.month ?? 0 }

  /// Day component, or `0` when absent.
  public var days: Int { components.day ?? 0 }

  /// Hour component, or `0` when absent.
  public var hours: Int { components.hour ?? 0 }

  /// Minute component, or `0` when absent.
  public var minutes: Int { components.minute ?? 0 }

  /// Second component, or `0` when absent.
  public var seconds: Int { components.second ?? 0 }

  /// Absolute magnitude of ``totalSeconds``.
  public var absoluteTotalSeconds: TimeInterval { abs(totalSeconds) }

  /// Whether the other instant is after the base instant.
  public var isPositive: Bool { totalSeconds > 0 }

  /// Whether the other instant is before the base instant.
  public var isNegative: Bool { totalSeconds < 0 }
}
