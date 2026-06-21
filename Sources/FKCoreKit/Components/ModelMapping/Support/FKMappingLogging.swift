import Foundation

/// Opt-in mapping trace logging.
public protocol FKMappingLogging: Sendable {
  /// Called after a successful decode.
  func didDecode(type: Any.Type, path: String?, duration: TimeInterval)
  /// Called after a mapping failure.
  func didFail(error: FKMappingError, preview: Data?)
}

/// Default no-op logger.
public struct FKNoOpMappingLogger: FKMappingLogging {
  /// Creates a no-op logger.
  public init() {}

  public func didDecode(type: Any.Type, path: String?, duration: TimeInterval) {}
  public func didFail(error: FKMappingError, preview: Data?) {}
}
