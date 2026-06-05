import Foundation

/// How media is delivered to the player (file, streaming protocol, etc.).
public enum FKMediaDelivery: Sendable, Equatable {
  case file
  case progressiveHTTP
  case hls(onDemand: Bool)
  case rtmp
  case rtsp
  case dash
  case httpFLV
}

extension FKMediaDelivery {

  /// Whether this delivery mode can carry live streams.
  public var isLiveCapable: Bool {
    switch self {
    case .hls, .rtmp, .rtsp, .httpFLV, .dash:
      return true
    case .file, .progressiveHTTP:
      return false
    }
  }

  /// Human-readable label for logging and errors.
  public var displayName: String {
    switch self {
    case .file: return FKUIKitI18n.string("fkuikit.media.delivery.file")
    case .progressiveHTTP: return FKUIKitI18n.string("fkuikit.media.delivery.progressive_http")
    case let .hls(onDemand): return onDemand
      ? FKUIKitI18n.string("fkuikit.media.delivery.hls_vod")
      : FKUIKitI18n.string("fkuikit.media.delivery.hls_live")
    case .rtmp: return FKUIKitI18n.string("fkuikit.media.delivery.rtmp")
    case .rtsp: return FKUIKitI18n.string("fkuikit.media.delivery.rtsp")
    case .dash: return FKUIKitI18n.string("fkuikit.media.delivery.dash")
    case .httpFLV: return FKUIKitI18n.string("fkuikit.media.delivery.http_flv")
    }
  }
}
