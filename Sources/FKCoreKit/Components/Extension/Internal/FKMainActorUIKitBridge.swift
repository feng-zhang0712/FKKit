#if canImport(UIKit)
import UIKit

/// Bridges nonisolated FKCoreKit helpers to MainActor-isolated `UIDevice` / `UIScreen` APIs.
public enum FKMainActorUIKitBridge {
  public nonisolated static func systemVersion() -> String {
    executeOnMain { UIDevice.current.systemVersion }
  }

  public nonisolated static func screenBoundsSize() -> CGSize {
    executeOnMain { UIScreen.main.bounds.size }
  }

  public nonisolated static func screenScale() -> CGFloat {
    executeOnMain { UIScreen.main.scale }
  }

  public nonisolated static func batteryLevel() -> Float {
    executeOnMain {
      UIDevice.current.isBatteryMonitoringEnabled = true
      return UIDevice.current.batteryLevel
    }
  }

  public nonisolated static func batteryStateDescription() -> String {
    executeOnMain {
      UIDevice.current.isBatteryMonitoringEnabled = true
      switch UIDevice.current.batteryState {
      case .unknown: return "unknown"
      case .unplugged: return "unplugged"
      case .charging: return "charging"
      case .full: return "full"
      @unknown default: return "unknown"
      }
    }
  }

  public nonisolated static func identifierForVendorUUIDString() -> String {
    executeOnMain {
      UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
  }

  /// Runs `body` on the main actor, hopping synchronously when needed.
  public nonisolated static func executeOnMain<T: Sendable>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
      return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
      MainActor.assumeIsolated(body)
    }
  }

  /// Reads ``UIAccessibility/isReduceMotionEnabled`` from a nonisolated context.
  public nonisolated static func isReduceMotionEnabled() -> Bool {
    executeOnMain { UIAccessibility.isReduceMotionEnabled }
  }

  /// Reads ``UIAccessibility/isReduceTransparencyEnabled`` from a nonisolated context.
  public nonisolated static func isReduceTransparencyEnabled() -> Bool {
    executeOnMain { UIAccessibility.isReduceTransparencyEnabled }
  }
}
#endif
