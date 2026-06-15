import Foundation

/// Captures ``FKPluggableLogging`` lines for test assertions.
public final class FKMockPluggableLogger: FKPluggableLogging, @unchecked Sendable {
  /// One captured log entry.
  public struct Entry: Sendable, Equatable {
    /// Log severity.
    public var level: FKPluggableLogLevel
    /// Message text.
    public var message: String
    /// Source file identifier.
    public var file: String
    /// Function name.
    public var function: String
    /// Line number.
    public var line: UInt
  }

  private let lock = NSLock()
  private var entries: [Entry] = []

  /// Minimum level emitted by the mock.
  public var minimumLevel: FKPluggableLogLevel = .debug

  /// Creates a mock logger.
  public init() {}

  /// Appends a log line when it passes ``minimumLevel``.
  public func log(
    level: FKPluggableLogLevel,
    _ message: @autoclosure () -> String,
    file: String,
    function: String,
    line: UInt
  ) {
    guard level >= minimumLevel else { return }
    let entry = Entry(
      level: level,
      message: message(),
      file: file,
      function: function,
      line: line
    )
    lock.lock()
    entries.append(entry)
    lock.unlock()
  }

  /// Returns all captured entries.
  public func capturedEntries() -> [Entry] {
    lock.lock()
    defer { lock.unlock() }
    return entries
  }

  /// Clears captured entries.
  public func reset() {
    lock.lock()
    entries = []
    lock.unlock()
  }
}
