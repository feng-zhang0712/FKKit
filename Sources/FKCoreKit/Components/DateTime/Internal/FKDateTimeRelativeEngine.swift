import Foundation

/// Builds localized relative timestamps (WeChat-like chat/feed + conversational + system).
enum FKDateTimeRelativeEngine {
  static func string(
    for date: Date,
    reference: Date,
    style: FKDateTimeRelativeStyle,
    configuration: FKDateTimeConfiguration
  ) -> String {
    switch style {
    case .chat:
      return chat(date: date, reference: reference, configuration: configuration)
    case .feed:
      return feed(date: date, reference: reference, configuration: configuration)
    case .standard:
      return standard(date: date, reference: reference, configuration: configuration)
    case .system(let unitsStyle):
      return system(date: date, reference: reference, unitsStyle: unitsStyle, locale: configuration.locale)
    }
  }

  // MARK: - WeChat chat

  private static func chat(
    date: Date,
    reference: Date,
    configuration: FKDateTimeConfiguration
  ) -> String {
    let calendar = configuration.calendar
    let timeText = FKDateTimeFormatting.string(
      from: date,
      format: FKDateTimeFormatPreset.timeShort.rawValue,
      configuration: configuration
    )

    if calendar.isDate(date, inSameDayAs: reference) {
      return timeText
    }

    if isSameCalendarDay(date, asReference: reference, offsetByDays: -1, calendar: calendar) {
      return FKI18n.format("fkcore.datetime.yesterday_at", timeText)
    }

    if let dayDelta = dayDistance(from: date, to: reference, calendar: calendar),
       dayDelta > 0,
       dayDelta < 7 {
      let weekday = FKDateTimeFormatting.string(
        from: date,
        format: "EEE",
        configuration: configuration
      )
      return FKI18n.format("fkcore.datetime.weekday_at", weekday, timeText)
    }

    if calendar.isDate(date, equalTo: reference, toGranularity: .year) {
      return FKDateTimeFormatting.string(
        from: date,
        format: "MM-dd HH:mm",
        configuration: configuration
      )
    }

    return FKDateTimeFormatting.string(
      from: date,
      format: "yyyy-MM-dd HH:mm",
      configuration: configuration
    )
  }

  // MARK: - WeChat feed / Moments

  private static func feed(
    date: Date,
    reference: Date,
    configuration: FKDateTimeConfiguration
  ) -> String {
    let calendar = configuration.calendar
    let elapsed = reference.timeIntervalSince(date)

    if elapsed < 0 {
      return standard(date: date, reference: reference, configuration: configuration)
    }

    if elapsed < 60 {
      return FKI18n.string("fkcore.datetime.just_now")
    }

    let minutes = Int(elapsed / 60)
    if minutes < 60 {
      return FKI18n.format("fkcore.datetime.minutes_ago", minutes)
    }

    let hours = minutes / 60
    if hours < 24, calendar.isDate(date, inSameDayAs: reference) {
      return FKI18n.format("fkcore.datetime.hours_ago", hours)
    }

    if isSameCalendarDay(date, asReference: reference, offsetByDays: -1, calendar: calendar) {
      return FKI18n.string("fkcore.datetime.yesterday")
    }

    if calendar.isDate(date, equalTo: reference, toGranularity: .year) {
      return FKDateTimeFormatting.string(
        from: date,
        format: FKDateTimeFormatPreset.monthDay.rawValue,
        configuration: configuration
      )
    }

    return FKDateTimeFormatting.string(
      from: date,
      format: FKDateTimeFormatPreset.date.rawValue,
      configuration: configuration
    )
  }

  // MARK: - Standard conversational

  private static func standard(
    date: Date,
    reference: Date,
    configuration: FKDateTimeConfiguration
  ) -> String {
    let calendar = configuration.calendar
    let elapsed = Int(reference.timeIntervalSince(date))

    if elapsed >= 0 {
      return pastStandard(
        date: date,
        elapsed: elapsed,
        reference: reference,
        calendar: calendar,
        configuration: configuration
      )
    }
    return futureStandard(
      date: date,
      remaining: -elapsed,
      reference: reference,
      calendar: calendar,
      configuration: configuration
    )
  }

  private static func pastStandard(
    date: Date,
    elapsed: Int,
    reference: Date,
    calendar: Calendar,
    configuration: FKDateTimeConfiguration
  ) -> String {
    if elapsed < 30 {
      return FKI18n.string("fkcore.datetime.just_now")
    }
    if elapsed < 60 {
      return FKI18n.format("fkcore.datetime.seconds_ago", elapsed)
    }

    let minutes = elapsed / 60
    if minutes < 60 {
      return FKI18n.format("fkcore.datetime.minutes_ago", minutes)
    }

    let hours = minutes / 60
    if hours < 24 {
      return FKI18n.format("fkcore.datetime.hours_ago", hours)
    }

    if isSameCalendarDay(date, asReference: reference, offsetByDays: -1, calendar: calendar) {
      let timeText = FKDateTimeFormatting.string(
        from: date,
        format: FKDateTimeFormatPreset.timeShort.rawValue,
        configuration: configuration
      )
      return FKI18n.format("fkcore.datetime.yesterday_at", timeText)
    }

    if isSameCalendarDay(date, asReference: reference, offsetByDays: -2, calendar: calendar) {
      return FKI18n.string("fkcore.datetime.day_before_yesterday")
    }

    if let days = dayDistance(from: date, to: reference, calendar: calendar), days > 0, days < 7 {
      return FKI18n.format("fkcore.datetime.days_ago", days)
    }

    if calendar.isDate(date, equalTo: reference, toGranularity: .year) {
      return FKDateTimeFormatting.string(from: date, format: "MM-dd HH:mm", configuration: configuration)
    }

    return FKDateTimeFormatting.string(
      from: date,
      format: FKDateTimeFormatPreset.dateTimeShort.rawValue,
      configuration: configuration
    )
  }

  private static func futureStandard(
    date: Date,
    remaining: Int,
    reference: Date,
    calendar: Calendar,
    configuration: FKDateTimeConfiguration
  ) -> String {
    if remaining < 30 {
      return FKI18n.string("fkcore.datetime.just_now")
    }
    if remaining < 60 {
      return FKI18n.format("fkcore.datetime.in_seconds", remaining)
    }

    let minutes = remaining / 60
    if minutes < 60 {
      return FKI18n.format("fkcore.datetime.in_minutes", minutes)
    }

    let hours = minutes / 60
    if hours < 24 {
      return FKI18n.format("fkcore.datetime.in_hours", hours)
    }

    if isSameCalendarDay(date, asReference: reference, offsetByDays: 1, calendar: calendar) {
      let timeText = FKDateTimeFormatting.string(
        from: date,
        format: FKDateTimeFormatPreset.timeShort.rawValue,
        configuration: configuration
      )
      return FKI18n.format("fkcore.datetime.tomorrow_at", timeText)
    }

    if let days = dayDistance(from: reference, to: date, calendar: calendar), days > 0, days < 7 {
      return FKI18n.format("fkcore.datetime.in_days", days)
    }

    if calendar.isDate(date, equalTo: reference, toGranularity: .year) {
      return FKDateTimeFormatting.string(from: date, format: "MM-dd HH:mm", configuration: configuration)
    }

    return FKDateTimeFormatting.string(
      from: date,
      format: FKDateTimeFormatPreset.dateTimeShort.rawValue,
      configuration: configuration
    )
  }

  // MARK: - System

  private static func system(
    date: Date,
    reference: Date,
    unitsStyle: RelativeDateTimeFormatter.UnitsStyle,
    locale: Locale
  ) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = locale
    formatter.unitsStyle = unitsStyle
    return formatter.localizedString(for: date, relativeTo: reference)
  }

  // MARK: - Helpers

  /// Whether `date` falls on the calendar day that is `offsetByDays` from `reference`’s day.
  ///
  /// Prefer this over `Calendar.isDateInYesterday` / `isDateInTomorrow`, which are anchored to
  /// the device’s current instant rather than a caller-supplied reference.
  private static func isSameCalendarDay(
    _ date: Date,
    asReference reference: Date,
    offsetByDays: Int,
    calendar: Calendar
  ) -> Bool {
    guard let target = calendar.date(byAdding: .day, value: offsetByDays, to: reference) else {
      return false
    }
    return calendar.isDate(date, inSameDayAs: target)
  }

  private static func dayDistance(from: Date, to: Date, calendar: Calendar) -> Int? {
    let start = calendar.startOfDay(for: from)
    let end = calendar.startOfDay(for: to)
    return calendar.dateComponents([.day], from: start, to: end).day
  }
}
