import Foundation

/// Bridges ``FKLogger`` to ``FKPluggableLogging`` for cross-module DI.
public final class FKLoggerPluggableAdapter: FKPluggableLogging, @unchecked Sendable {
  private let logger: FKLogger

  /// Minimum level emitted through the adapter.
  public var minimumLevel: FKPluggableLogLevel {
    get {
      let enabled = logger.config.enabledLevels
      if enabled.contains(.verbose) { return .verbose }
      if enabled.contains(.debug) { return .debug }
      if enabled.contains(.info) { return .info }
      if enabled.contains(.warning) { return .warning }
      return .error
    }
    set {
      logger.updateConfig { config in
        config.enabledLevels = Self.enabledLevels(from: newValue)
      }
    }
  }

  /// Creates an adapter around a logger instance.
  ///
  /// - Parameter logger: Production logger (default ``FKLogger/shared``).
  public init(logger: FKLogger = .shared) {
    self.logger = logger
  }

  /// Forwards a Pluggable log line to ``FKLogger``.
  public func log(
    level: FKPluggableLogLevel,
    _ message: @autoclosure () -> String,
    file: String,
    function: String,
    line: UInt
  ) {
    guard level >= minimumLevel else { return }
    let resolved = message()
    let fkLevel = Self.map(level)
    logger.log(
      fkLevel,
      message: { resolved },
      metadata: [:],
      file: file,
      function: function,
      line: Int(line)
    )
  }

  private static func map(_ level: FKPluggableLogLevel) -> FKLogLevel {
    switch level {
    case .verbose: .verbose
    case .debug: .debug
    case .info: .info
    case .warning: .warning
    case .error: .error
    }
  }

  private static func enabledLevels(from minimum: FKPluggableLogLevel) -> Set<FKLogLevel> {
    Set(FKPluggableLogLevel.allCases.filter { $0 >= minimum }.map(map))
  }
}
