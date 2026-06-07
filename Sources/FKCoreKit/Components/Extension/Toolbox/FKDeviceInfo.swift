import Darwin
import Foundation
import Network

#if canImport(UIKit)
import UIKit
#endif

/// Device, runtime, and app metadata helpers without a natural single receiver type.
public enum FKDeviceInfo {
  /// Returns device model identifier (for example `iPhone15,2`).
  public static func modelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) { ptr in
      ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { cPtr in
        String(cString: cPtr)
      }
    }
  }

  /// Returns current system version.
  public static func systemVersion() -> String {
    #if canImport(UIKit)
    FKMainActorUIKitBridge.systemVersion()
    #else
    ProcessInfo.processInfo.operatingSystemVersionString
    #endif
  }

  /// Returns screen size in points.
  public static func screenSize() -> CGSize {
    #if canImport(UIKit)
    FKMainActorUIKitBridge.screenBoundsSize()
    #else
    .zero
    #endif
  }

  /// Returns screen scale.
  public static func screenScale() -> CGFloat {
    #if canImport(UIKit)
    FKMainActorUIKitBridge.screenScale()
    #else
    1
    #endif
  }

  /// Returns screen resolution in pixels.
  public static func screenResolution() -> CGSize {
    let size = screenSize()
    let scale = screenScale()
    return CGSize(width: size.width * scale, height: size.height * scale)
  }

  /// Returns current battery level from 0 to 1, or `-1` when unavailable.
  public static func batteryLevel() -> Float {
    #if canImport(UIKit)
    FKMainActorUIKitBridge.batteryLevel()
    #else
    -1
    #endif
  }

  /// Returns localized battery state description.
  public static func batteryStateDescription() -> String {
    #if canImport(UIKit)
    switch FKMainActorUIKitBridge.batteryStateDescription() {
    case "unknown": return FKI18n.string("fkcore.utils.battery.state.unknown")
    case "unplugged": return FKI18n.string("fkcore.utils.battery.state.unplugged")
    case "charging": return FKI18n.string("fkcore.utils.battery.state.charging")
    case "full": return FKI18n.string("fkcore.utils.battery.state.full")
    case let state: return state
    }
    #else
    return "unknown"
    #endif
  }

  /// Returns localized network reachability status asynchronously (one-shot callback).
  public static func networkStatus(completion: @escaping @Sendable (String) -> Void) {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "com.fkkit.device.network")
    monitor.pathUpdateHandler = { path in
      let value: String
      if path.status != .satisfied {
        value = "unreachable"
      } else if path.usesInterfaceType(.wifi) {
        value = "wifi"
      } else if path.usesInterfaceType(.cellular) {
        value = "cellular"
      } else if path.usesInterfaceType(.wiredEthernet) {
        value = "ethernet"
      } else {
        value = "other"
      }
      let localized: String
      switch value {
      case "unreachable": localized = FKI18n.string("fkcore.utils.network.unreachable")
      case "wifi": localized = FKI18n.string("fkcore.utils.network.wifi")
      case "cellular": localized = FKI18n.string("fkcore.utils.network.cellular")
      case "ethernet": localized = FKI18n.string("fkcore.utils.network.ethernet")
      case "other": localized = FKI18n.string("fkcore.utils.network.other")
      default: localized = value
      }
      completion(localized)
      monitor.cancel()
    }
    monitor.start(queue: queue)
  }

  /// Returns free and total disk space in bytes.
  public static func diskSpace() -> (free: Int64, total: Int64) {
    guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
          let free = attrs[.systemFreeSize] as? NSNumber,
          let total = attrs[.systemSize] as? NSNumber else {
      return (0, 0)
    }
    return (free.int64Value, total.int64Value)
  }

  /// Returns memory usage details in bytes.
  public static func memoryStatus() -> (used: UInt64, free: UInt64, total: UInt64) {
    let total = ProcessInfo.processInfo.physicalMemory
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
    let result = withUnsafeMutablePointer(to: &stats) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }
    guard result == KERN_SUCCESS else { return (0, 0, total) }
    var kernelPageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &kernelPageSize) == KERN_SUCCESS else {
      return (0, 0, total)
    }
    let pageSize = UInt64(kernelPageSize)
    let free = UInt64(stats.free_count) * pageSize
    let used = total > free ? total - free : 0
    return (used, free, total)
  }

  /// Returns a stable vendor identifier when available; not a permanent global device ID.
  public static func vendorIdentifier() -> String {
    #if canImport(UIKit)
    FKMainActorUIKitBridge.identifierForVendorUUIDString()
    #else
    UUID().uuidString
    #endif
  }
}
