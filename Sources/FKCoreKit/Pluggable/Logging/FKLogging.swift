import Foundation

/// Severity for ``FKPluggableLogging`` implementations.
///
/// Prefixed to avoid clashing with ``FKLogLevel`` in the Logger module.
public enum FKPluggableLogLevel: Int, Sendable, Comparable, CaseIterable {
  case verbose = 0
  case debug = 1
  case info = 2
  case warning = 3
  case error = 4

  public static func < (lhs: FKPluggableLogLevel, rhs: FKPluggableLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// Pluggable logger used across networking, analytics, and UI kits.
///
/// Wire a console logger in debug and a redacted file/OSLog logger in production.
public protocol FKPluggableLogging: Sendable {
  /// Minimum level emitted by this logger.
  var minimumLevel: FKPluggableLogLevel { get set }

  /// Writes a log line.
  ///
  /// - Parameters:
  ///   - level: Severity.
  ///   - message: Human-readable message.
  ///   - file: Source file identifier.
  ///   - function: Function name.
  ///   - line: Line number.
  func log(
    level: FKPluggableLogLevel,
    _ message: @autoclosure () -> String,
    file: String,
    function: String,
    line: UInt
  )
}

/// Convenience helpers for ``FKPluggableLogging`` conformers.
public extension FKPluggableLogging {
  /// Logs at `.debug` level.
  func debug(
    _ message: @autoclosure () -> String,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(level: .debug, message(), file: file, function: function, line: line)
  }

  /// Logs at `.info` level.
  func info(
    _ message: @autoclosure () -> String,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(level: .info, message(), file: file, function: function, line: line)
  }

  /// Logs at `.error` level.
  func error(
    _ message: @autoclosure () -> String,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    log(level: .error, message(), file: file, function: function, line: line)
  }
}
