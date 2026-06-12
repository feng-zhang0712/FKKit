import Foundation

/// Controls whether the scanner keeps running after a successful read.
public enum FKQRCodeScanMode: Sendable, Equatable {
  /// Pauses capture after the first successful scan.
  case once
  /// Keeps scanning; duplicate payloads are suppressed by ``FKQRCodeScannerConfiguration/cooldownInterval``.
  case continuous
}
