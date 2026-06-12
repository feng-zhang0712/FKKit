#if canImport(SwiftUI)
import FKCoreKit
import SwiftUI
import UIKit

/// SwiftUI wrapper around ``FKQRCodeScannerViewController``.
@MainActor
public struct FKQRCodeScannerRepresentable: UIViewControllerRepresentable {
  private let configuration: FKQRCodeScannerConfiguration
  private let onScan: (FKQRCodePayload) -> Void
  private let onCancel: () -> Void
  private let onError: (FKQRCodeScannerError) -> Void

  /// Creates a representable scanner.
  public init(
    configuration: FKQRCodeScannerConfiguration = .default,
    onScan: @escaping (FKQRCodePayload) -> Void,
    onCancel: @escaping () -> Void = {},
    onError: @escaping (FKQRCodeScannerError) -> Void = { _ in }
  ) {
    self.configuration = configuration
    self.onScan = onScan
    self.onCancel = onCancel
    self.onError = onError
  }

  public func makeUIViewController(context: Context) -> FKQRCodeScannerViewController {
    let controller = FKQRCodeScannerViewController(configuration: configuration)
    controller.delegate = context.coordinator
    return controller
  }

  public func updateUIViewController(_ uiViewController: FKQRCodeScannerViewController, context: Context) {
    if uiViewController.configuration != configuration {
      uiViewController.configuration = configuration
    }
    context.coordinator.onScan = onScan
    context.coordinator.onCancel = onCancel
    context.coordinator.onError = onError
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(onScan: onScan, onCancel: onCancel, onError: onError)
  }

  @MainActor
  public final class Coordinator: NSObject, FKQRCodeScannerDelegate {
    var onScan: (FKQRCodePayload) -> Void
    var onCancel: () -> Void
    var onError: (FKQRCodeScannerError) -> Void

    init(
      onScan: @escaping (FKQRCodePayload) -> Void,
      onCancel: @escaping () -> Void,
      onError: @escaping (FKQRCodeScannerError) -> Void
    ) {
      self.onScan = onScan
      self.onCancel = onCancel
      self.onError = onError
    }

    public func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didScan payload: FKQRCodePayload) {
      onScan(payload)
    }

    public func qrCodeScannerDidCancel(_ scanner: FKQRCodeScannerViewController) {
      onCancel()
    }

    public func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError) {
      onError(error)
    }
  }
}
#endif
