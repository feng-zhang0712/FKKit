import Foundation

/// Shared analytics common-parameter keys produced from ``FKBusinessInfoProviding``.
public enum FKBusinessAnalyticsCommonParameters {
  /// Builds the standard BusinessKit common-parameter dictionary for analytics events.
  ///
  /// Keys match ``FKBusinessAnalyticsTracker`` merge behavior (`bundle_id`, `app_version`, …).
  public static func standard(from info: FKBusinessInfoProviding) -> [String: String] {
    let size = info.screenSize
    return [
      "bundle_id": info.bundleID,
      "app_version": info.appVersion,
      "build": info.buildNumber,
      "os": "iOS",
      "os_version": info.systemVersion,
      "device_model": info.deviceModelIdentifier,
      "screen_size": "\(Int(size.width))x\(Int(size.height))",
      "channel": info.channel,
      "env": info.environment.rawValue,
    ]
  }
}
