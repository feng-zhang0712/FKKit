import AVFoundation
import FKCoreKit
import Foundation

/// Manages `AVCaptureSession` lifecycle on a dedicated serial queue.
final class FKQRCodeCaptureSessionController: NSObject, @unchecked Sendable {
  private let sessionQueue = DispatchQueue(label: "com.fkkit.qrcode.capture", qos: .userInitiated)
  private let metadataQueue = DispatchQueue(label: "com.fkkit.qrcode.metadata", qos: .userInitiated)
  private let session = AVCaptureSession()
  private var metadataOutput: AVCaptureMetadataOutput?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var isConfigured = false

  var onMetadataString: (@MainActor (String) -> Void)?

  func attachPreviewLayer(to view: CALayer) -> AVCaptureVideoPreviewLayer {
    if let previewLayer {
      return previewLayer
    }
    let layer = AVCaptureVideoPreviewLayer(session: session)
    layer.videoGravity = .resizeAspectFill
    layer.frame = view.bounds
    view.insertSublayer(layer, at: 0)
    previewLayer = layer
    return layer
  }

  func updatePreviewFrame(_ frame: CGRect) {
    DispatchQueue.main.async { [weak self] in
      self?.previewLayer?.frame = frame
    }
  }

  func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
    sessionQueue.async { [weak self] in
      guard let connection = self?.previewLayer?.connection else { return }
      if connection.isVideoOrientationSupported {
        connection.videoOrientation = orientation
      }
    }
  }

  func configureIfNeeded() -> Bool {
    if isConfigured { return true }

    session.beginConfiguration()
    defer { session.commitConfiguration() }

    session.sessionPreset = .high

    guard let device = AVCaptureDevice.default(for: .video) else {
      return false
    }

    do {
      let input = try AVCaptureDeviceInput(device: device)
      guard session.canAddInput(input) else { return false }
      session.addInput(input)
    } catch {
      FKLogD("FKQRCode capture input failed", metadata: ["error": String(describing: error)])
      return false
    }

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else { return false }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: metadataQueue)
    output.metadataObjectTypes = [.qr]
    metadataOutput = output
    isConfigured = true
    return true
  }

  func startRunning() {
    sessionQueue.async { [weak self] in
      guard let self, self.isConfigured, !self.session.isRunning else { return }
      self.session.startRunning()
    }
  }

  func stopRunning() {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.session.stopRunning()
    }
  }

  func setTorchEnabled(_ enabled: Bool) {
    sessionQueue.async {
      guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
      do {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        device.torchMode = enabled ? .on : .off
      } catch {
        FKLogD("FKQRCode torch toggle failed", metadata: ["error": String(describing: error)])
      }
    }
  }

  func turnTorchOff() {
    setTorchEnabled(false)
  }

  static var isCameraAvailable: Bool {
    AVCaptureDevice.default(for: .video) != nil
  }
}

extension FKQRCodeCaptureSessionController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
          object.type == .qr,
          let value = object.stringValue else {
      return
    }

    let callback = onMetadataString
    Task { @MainActor in
      callback?(value)
    }
  }
}
