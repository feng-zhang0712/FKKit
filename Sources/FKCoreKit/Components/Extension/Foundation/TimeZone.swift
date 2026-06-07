import Foundation

public extension TimeZone {
  /// UTC time zone (zero offset from GMT).
  static var fk_utc: TimeZone {
    TimeZone(secondsFromGMT: 0)!
  }
}
