import FKCoreKit
import UIKit

/// Callbacks from ``FKQRCodeScannerViewController``.
@MainActor
public protocol FKQRCodeScannerDelegate: AnyObject {
  /// Called when a QR code is successfully scanned and parsed.
  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didScan payload: FKQRCodePayload)
  /// Called when the user dismisses the scanner without a result.
  func qrCodeScannerDidCancel(_ scanner: FKQRCodeScannerViewController)
  /// Called when the scanner fails to start or recover.
  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError)
}

public extension FKQRCodeScannerDelegate {
  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError) {}
}
