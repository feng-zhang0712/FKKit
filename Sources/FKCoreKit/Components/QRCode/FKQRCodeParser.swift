import Foundation

/// Parses raw QR code strings into typed ``FKQRCodePayload`` values.
public enum FKQRCodeParser {
  /// Parses a scanned or pasted QR string.
  ///
  /// - Parameter rawValue: Raw metadata string from `AVCaptureMetadataOutput`.
  /// - Returns: A typed payload; empty strings become `.unknown("")`.
  public static func parse(_ rawValue: String) -> FKQRCodePayload {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return .unknown(trimmed)
    }

    if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), !scheme.isEmpty {
      if scheme == "http" || scheme == "https" || isCustomURLScheme(scheme) {
        return .url(url)
      }
    }

    if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://"),
       let url = URL(string: trimmed) {
      return .url(url)
    }

    return .text(trimmed)
  }

  private static func isCustomURLScheme(_ scheme: String) -> Bool {
    guard let first = scheme.unicodeScalars.first else { return false }
    return CharacterSet.letters.contains(first) || CharacterSet.decimalDigits.contains(first)
  }
}
