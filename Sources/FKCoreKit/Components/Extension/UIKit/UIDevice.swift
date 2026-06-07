#if canImport(UIKit)
import UIKit

public extension UIDevice {
  /// Low-level machine identifier from `uname` (for example `iPhone15,2`).
  var fk_machineIdentifier: String {
    FKDeviceInfo.modelIdentifier()
  }

  /// `true` when running an iOS simulator.
  var fk_isSimulator: Bool {
    #if targetEnvironment(simulator)
      true
    #else
      false
    #endif
  }
}

#endif
