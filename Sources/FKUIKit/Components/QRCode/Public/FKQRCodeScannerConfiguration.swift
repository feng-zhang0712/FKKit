import FKCoreKit
import Foundation

/// Configuration for ``FKQRCodeScannerViewController``.
public struct FKQRCodeScannerConfiguration: Sendable, Equatable {
  /// Whether to pause after the first scan or keep running.
  public var scanMode: FKQRCodeScanMode
  /// Minimum interval before the same raw payload can fire again when ``allowsMultipleCallbacks`` is `false`.
  public var cooldownInterval: TimeInterval
  /// When `false`, identical payloads within ``cooldownInterval`` are ignored.
  public var allowsMultipleCallbacks: Bool
  /// Shows a torch toggle when the device supports it.
  public var showsTorchButton: Bool
  /// Scan frame overlay styling.
  public var overlayStyle: FKQRCodeOverlayStyle
  /// Optional pre-permission guide shown before the system camera prompt.
  public var permissionPrePrompt: FKPermissionPrePrompt?
  /// Automatic URL handling after a successful scan.
  public var navigationPolicy: FKQRCodeNavigationPolicy
  /// Plays haptic feedback on successful scan.
  public var hapticsOnSuccess: Bool
  /// Announces scan success for VoiceOver.
  public var announcesScanSuccess: Bool
  /// Raw string injected by the simulator mock UI when no camera is available.
  public var simulatorMockRawValue: String

  /// Default scanner configuration.
  public static let `default` = FKQRCodeScannerConfiguration()

  /// Creates scanner configuration.
  public init(
    scanMode: FKQRCodeScanMode = .once,
    cooldownInterval: TimeInterval = 2.0,
    allowsMultipleCallbacks: Bool = false,
    showsTorchButton: Bool = true,
    overlayStyle: FKQRCodeOverlayStyle = .default,
    permissionPrePrompt: FKPermissionPrePrompt? = nil,
    navigationPolicy: FKQRCodeNavigationPolicy = .callbackOnly,
    hapticsOnSuccess: Bool = true,
    announcesScanSuccess: Bool = true,
    simulatorMockRawValue: String = "https://example.com"
  ) {
    self.scanMode = scanMode
    self.cooldownInterval = cooldownInterval
    self.allowsMultipleCallbacks = allowsMultipleCallbacks
    self.showsTorchButton = showsTorchButton
    self.overlayStyle = overlayStyle
    self.permissionPrePrompt = permissionPrePrompt
    self.navigationPolicy = navigationPolicy
    self.hapticsOnSuccess = hapticsOnSuccess
    self.announcesScanSuccess = announcesScanSuccess
    self.simulatorMockRawValue = simulatorMockRawValue
  }
}
