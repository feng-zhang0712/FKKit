import Foundation

/// Typed result of parsing a scanned or supplied QR code string.
public enum FKQRCodePayload: Sendable, Equatable {
  /// HTTP(S) or custom-scheme URL payload.
  case url(URL)
  /// Plain text payload.
  case text(String)
  /// Unrecognized or empty raw value preserved for host inspection.
  case unknown(String)
}

public extension FKQRCodePayload {
  /// The original string representation suitable for logging-free display.
  var rawValue: String {
    switch self {
    case let .url(url):
      return url.absoluteString
    case let .text(text):
      return text
    case let .unknown(value):
      return value
    }
  }
}
