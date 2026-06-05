import Foundation

/// Resolves battery state tokens for ``FKUtilsDevice/batteryState()``.
enum FKCoreKitBatteryStateI18n {
  static func localized(_ state: String) -> String {
    switch state {
    case "unknown": return FKI18n.string("fkcore.utils.battery.state.unknown")
    case "unplugged": return FKI18n.string("fkcore.utils.battery.state.unplugged")
    case "charging": return FKI18n.string("fkcore.utils.battery.state.charging")
    case "full": return FKI18n.string("fkcore.utils.battery.state.full")
    default: return state
    }
  }
}

/// Resolves network reachability tokens for ``FKUtilsDevice/networkStatus(completion:)``.
enum FKCoreKitNetworkStatusI18n {
  static func localized(_ status: String) -> String {
    switch status {
    case "unreachable": return FKI18n.string("fkcore.utils.network.unreachable")
    case "wifi": return FKI18n.string("fkcore.utils.network.wifi")
    case "cellular": return FKI18n.string("fkcore.utils.network.cellular")
    case "ethernet": return FKI18n.string("fkcore.utils.network.ethernet")
    case "other": return FKI18n.string("fkcore.utils.network.other")
    default: return status
    }
  }
}
