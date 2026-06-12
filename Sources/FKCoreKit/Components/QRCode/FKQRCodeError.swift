import Foundation

/// Errors thrown by ``FKQRCodeGenerator``.
public enum FKQRCodeError: Error, Sendable, Equatable {
  /// The input string is empty after trimming whitespace.
  case emptyContent
  /// UTF-8 payload exceeds the documented QR binary-mode limit.
  case contentTooLong(maxBytes: Int)
  /// `CIQRCodeGenerator` failed to produce output.
  case filterFailed
  /// Failed to convert a `CIImage` into a bitmap image.
  case imageConversionFailed
}

extension FKQRCodeError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyContent:
      return FKI18n.string("fkcore.qrcode.error.empty_content")
    case let .contentTooLong(maxBytes):
      return FKI18n.format("fkcore.qrcode.error.content_too_long", maxBytes)
    case .filterFailed:
      return FKI18n.string("fkcore.qrcode.error.filter_failed")
    case .imageConversionFailed:
      return FKI18n.string("fkcore.qrcode.error.image_conversion_failed")
    }
  }
}
