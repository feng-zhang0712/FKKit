#if os(iOS)
import Foundation

public extension FKLocalNotificationManager {
  /// Routes notification deeplink URLs through ``FKBusinessKit/shared`` deeplink router.
  ///
  /// Uses ``FKDeeplinkSource/unknown`` until BusinessKit adds a `.localNotification` source (v1.1).
  func useBusinessKitDeeplink() {
    setDeeplinkRouter { url in
      FKBusinessKit.shared.deeplink.route(url, source: .unknown)
    }
  }
}

#endif
