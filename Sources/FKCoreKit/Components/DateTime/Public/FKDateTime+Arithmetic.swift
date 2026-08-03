import Foundation

// MARK: - Arithmetic

public extension FKDateTime {
  /// Adds `value` calendar units and returns a new instance.
  func adding(_ value: Int, _ unit: FKDateTimeUnit) -> FKDateTime? {
    guard let next = configuration.calendar.date(
      byAdding: unit.calendarComponent,
      value: value,
      to: date
    ) else { return nil }
    return FKDateTime(next, configuration: configuration)
  }

  /// Subtracts `value` calendar units (convenience for `adding(-value, unit)`).
  func subtracting(_ value: Int, _ unit: FKDateTimeUnit) -> FKDateTime? {
    adding(-value, unit)
  }

  /// Adds mixed calendar components.
  func adding(_ components: DateComponents) -> FKDateTime? {
    guard let next = configuration.calendar.date(byAdding: components, to: date) else { return nil }
    return FKDateTime(next, configuration: configuration)
  }

  /// Start of the calendar unit containing this instant (day / week / month / year / …).
  func startOf(_ unit: FKDateTimeUnit) -> FKDateTime? {
    guard let interval = configuration.calendar.dateInterval(of: unit.calendarComponent, for: date) else {
      return nil
    }
    return FKDateTime(interval.start, configuration: configuration)
  }

  /// Inclusive end of the calendar unit (last representable instant before the next unit’s start).
  ///
  /// Uses the next-lower `TimeInterval` before the exclusive interval end so `.second` / `.minute`
  /// boundaries stay correct (unlike subtracting a whole second).
  func endOf(_ unit: FKDateTimeUnit) -> FKDateTime? {
    guard let interval = configuration.calendar.dateInterval(of: unit.calendarComponent, for: date) else {
      return nil
    }
    let inclusiveEnd = Date(
      timeIntervalSinceReferenceDate: interval.end.timeIntervalSinceReferenceDate.nextDown
    )
    return FKDateTime(inclusiveEnd, configuration: configuration)
  }

  /// Convenience for ``startOf(_:)`` with `.day`.
  var startOfDay: FKDateTime? { startOf(.day) }

  /// Convenience for ``endOf(_:)`` with `.day`.
  var endOfDay: FKDateTime? { endOf(.day) }

  /// Returns a copy with selected calendar fields replaced (unspecified fields keep their current values).
  ///
  /// - Returns: `nil` when the calendar cannot compose a valid date (for example an invalid day-of-month).
  func replacing(
    year: Int? = nil,
    month: Int? = nil,
    day: Int? = nil,
    hour: Int? = nil,
    minute: Int? = nil,
    second: Int? = nil
  ) -> FKDateTime? {
    var components = configuration.calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: date
    )
    if let year { components.year = year }
    if let month { components.month = month }
    if let day { components.day = day }
    if let hour { components.hour = hour }
    if let minute { components.minute = minute }
    if let second { components.second = second }
    guard let next = configuration.calendar.date(from: components) else { return nil }
    return FKDateTime(next, configuration: configuration)
  }

  /// Returns a copy with a single calendar unit set to `value`.
  ///
  /// - Note: Relies on `Calendar.date(bySetting:value:of:)`. Prefer ``setting(hour:minute:second:)``
  ///   when adjusting wall-clock time, and ``replacing(year:month:day:hour:minute:second:)`` for
  ///   multi-field updates.
  func setting(_ unit: FKDateTimeUnit, to value: Int) -> FKDateTime? {
    guard let next = configuration.calendar.date(
      bySetting: unit.calendarComponent,
      value: value,
      of: date
    ) else { return nil }
    return FKDateTime(next, configuration: configuration)
  }

  /// Returns a copy on the same calendar day with the given wall-clock time.
  func setting(hour: Int, minute: Int, second: Int = 0) -> FKDateTime? {
    guard let next = configuration.calendar.date(
      bySettingHour: hour,
      minute: minute,
      second: second,
      of: date
    ) else { return nil }
    return FKDateTime(next, configuration: configuration)
  }
}

// MARK: - Components & queries

public extension FKDateTime {
  /// Year component.
  var year: Int { configuration.calendar.component(.year, from: date) }

  /// Month component (`1...12`).
  var month: Int { configuration.calendar.component(.month, from: date) }

  /// Day of month.
  var day: Int { configuration.calendar.component(.day, from: date) }

  /// Hour (`0...23`).
  var hour: Int { configuration.calendar.component(.hour, from: date) }

  /// Minute (`0...59`).
  var minute: Int { configuration.calendar.component(.minute, from: date) }

  /// Second (`0...59`).
  var second: Int { configuration.calendar.component(.second, from: date) }

  /// Weekday (`1...7`, calendar-dependent; Gregorian typically Sunday = 1).
  var weekday: Int { configuration.calendar.component(.weekday, from: date) }

  /// Week of year.
  var weekOfYear: Int { configuration.calendar.component(.weekOfYear, from: date) }

  /// Quarter of year (`1...4`).
  var quarter: Int { configuration.calendar.component(.quarter, from: date) }

  /// Day of year (`1...366`), computed from the start of the calendar year.
  var dayOfYear: Int {
    let start = configuration.calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? date
    return (configuration.calendar.dateComponents([.day], from: start, to: date).day ?? 0) + 1
  }

  /// Whether this instant falls on today.
  var isToday: Bool { configuration.calendar.isDateInToday(date) }

  /// Whether this instant falls on yesterday.
  var isYesterday: Bool { configuration.calendar.isDateInYesterday(date) }

  /// Whether this instant falls on tomorrow.
  var isTomorrow: Bool { configuration.calendar.isDateInTomorrow(date) }

  /// Whether the weekday is a weekend day for the configured calendar.
  var isWeekend: Bool { configuration.calendar.isDateInWeekend(date) }

  /// Whether the year is a leap year in the configured calendar.
  var isLeapYear: Bool {
    configuration.calendar.range(of: .day, in: .year, for: date)?.count == 366
  }

  /// Number of days in the month containing this instant.
  var daysInMonth: Int {
    configuration.calendar.range(of: .day, in: .month, for: date)?.count ?? 0
  }

  /// Whether this instant shares the same calendar unit bucket as `other`.
  func isSame(_ unit: FKDateTimeUnit, as other: FKDateTime) -> Bool {
    configuration.calendar.isDate(date, equalTo: other.date, toGranularity: unit.calendarComponent)
  }

  /// Compares this instant to `other` at `granularity` (for example same calendar day).
  func compare(to other: FKDateTime, granularity: FKDateTimeUnit) -> ComparisonResult {
    configuration.calendar.compare(date, to: other.date, toGranularity: granularity.calendarComponent)
  }

  /// Whether this instant is strictly before `other`.
  func isBefore(_ other: FKDateTime) -> Bool { date < other.date }

  /// Whether this instant is strictly after `other`.
  func isAfter(_ other: FKDateTime) -> Bool { date > other.date }

  /// Whether this instant is before or equal to `other`.
  func isSameOrBefore(_ other: FKDateTime) -> Bool { date <= other.date }

  /// Whether this instant is after or equal to `other`.
  func isSameOrAfter(_ other: FKDateTime) -> Bool { date >= other.date }

  /// Whether this instant is before or equal to `other` at `granularity`.
  func isSameOrBefore(_ other: FKDateTime, granularity: FKDateTimeUnit) -> Bool {
    compare(to: other, granularity: granularity) != .orderedDescending
  }

  /// Whether this instant is after or equal to `other` at `granularity`.
  func isSameOrAfter(_ other: FKDateTime, granularity: FKDateTimeUnit) -> Bool {
    compare(to: other, granularity: granularity) != .orderedAscending
  }

  /// Whether this instant is strictly before `reference` (default: now).
  func isPast(reference: Date = Date()) -> Bool { date < reference }

  /// Whether this instant is strictly after `reference` (default: now).
  func isFuture(reference: Date = Date()) -> Bool { date > reference }

  /// Whether this instant lies between `start` and `end`.
  func isBetween(_ start: FKDateTime, and end: FKDateTime, inclusive: Bool = true) -> Bool {
    if inclusive {
      return date >= start.date && date <= end.date
    }
    return date > start.date && date < end.date
  }

  /// Whole years elapsed from this instant to `reference` (useful for age).
  ///
  /// - Returns: Non-negative year difference, or `nil` when components cannot be computed.
  func age(at reference: FKDateTime = .now()) -> Int? {
    let components = configuration.calendar.dateComponents([.year], from: date, to: reference.date)
    guard let years = components.year else { return nil }
    return Swift.max(0, years)
  }
}

// MARK: - Diff

public extension FKDateTime {
  /// Difference in a single unit from this instant to `other` (`other − self`).
  func diff(_ other: FKDateTime, unit: FKDateTimeUnit) -> Int? {
    configuration.calendar.dateComponents(
      [unit.calendarComponent],
      from: date,
      to: other.date
    ).value(for: unit.calendarComponent)
  }

  /// Multi-unit calendar difference from this instant to `other`.
  func diff(to other: FKDateTime) -> FKDateTimeDiff {
    let components = configuration.calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: date,
      to: other.date
    )
    return FKDateTimeDiff(
      components: components,
      totalSeconds: other.date.timeIntervalSince(date)
    )
  }

  /// Signed day distance between calendar midnights (`other − self`).
  func daysUntil(_ other: FKDateTime) -> Int? {
    let start = configuration.calendar.startOfDay(for: date)
    let end = configuration.calendar.startOfDay(for: other.date)
    return configuration.calendar.dateComponents([.day], from: start, to: end).day
  }

  /// Localized span length from this instant to `other` (for timers, media duration, ETAs).
  ///
  /// Distinct from ``relative(style:reference:)`` social timestamps — this describes *how long*
  /// the interval is (for example `"2h 15m"`), not “2 hours ago”.
  ///
  /// - Parameters:
  ///   - other: Interval end (may be earlier or later than this instant; absolute components are used).
  ///   - allowedUnits: Units `DateComponentsFormatter` may include.
  ///   - unitsStyle: Presentation style (abbreviated / full / positional / …).
  ///   - maximumUnitCount: Caps how many units are shown (`0` = no limit).
  /// - Returns: Locale-aware description, or `nil` when formatting fails.
  func durationDescription(
    to other: FKDateTime,
    allowedUnits: NSCalendar.Unit = [.day, .hour, .minute, .second],
    unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated,
    maximumUnitCount: Int = 2
  ) -> String? {
    FKDateTimeFormatting.durationString(
      from: date,
      to: other.date,
      allowedUnits: allowedUnits,
      unitsStyle: unitsStyle,
      maximumUnitCount: maximumUnitCount,
      locale: configuration.locale,
      calendar: configuration.calendar
    )
  }
}

// MARK: - Min / max

public extension FKDateTime {
  /// Earlier of two instants (configuration taken from `lhs`).
  static func min(_ lhs: FKDateTime, _ rhs: FKDateTime) -> FKDateTime {
    lhs.date <= rhs.date ? lhs : FKDateTime(rhs.date, configuration: lhs.configuration)
  }

  /// Later of two instants (configuration taken from `lhs`).
  static func max(_ lhs: FKDateTime, _ rhs: FKDateTime) -> FKDateTime {
    lhs.date >= rhs.date ? lhs : FKDateTime(rhs.date, configuration: lhs.configuration)
  }
}
