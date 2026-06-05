import Foundation

/// Errors surfaced by the media playback core.
public enum FKMediaError: Error, Sendable, Equatable {
  case unsupportedFormat(FKMediaFormatDescriptor)
  case transcodingRequired(suggested: FKMediaDelivery)
  case networkUnavailable
  case httpStatus(code: Int)
  case drmFailed(message: String)
  case engineFailed(engine: FKMediaEngineKind, message: String)
  case seekFailed
  case cancelled
  case notImplemented(feature: String)
  case invalidState(String)
}

extension FKMediaError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case let .unsupportedFormat(descriptor):
      return FKUIKitI18n.format("fkuikit.media.error.unsupported_format", descriptor.container.rawValue)
    case let .transcodingRequired(suggested):
      return FKUIKitI18n.format("fkuikit.media.error.transcoding_required", suggested.displayName)
    case .networkUnavailable:
      return FKUIKitI18n.string("fkuikit.media.error.network_unavailable")
    case let .httpStatus(code):
      return FKUIKitI18n.format("fkuikit.media.error.http_status", code)
    case let .drmFailed(message):
      return FKUIKitI18n.format("fkuikit.media.error.drm_failed", message)
    case let .engineFailed(engine, message):
      return FKUIKitI18n.format("fkuikit.media.error.engine_failed", engine.rawValue, message)
    case .seekFailed:
      return FKUIKitI18n.string("fkuikit.media.error.seek_failed")
    case .cancelled:
      return FKUIKitI18n.string("fkuikit.common.cancelled")
    case let .notImplemented(feature):
      return FKUIKitI18n.format("fkuikit.media.error.not_implemented", feature)
    case let .invalidState(message):
      return FKUIKitI18n.format("fkuikit.media.error.invalid_state", message)
    }
  }
}
