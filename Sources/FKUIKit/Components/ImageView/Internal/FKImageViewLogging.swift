import FKCoreKit
import Foundation

enum FKImageViewLogging {
  static func debug(_ message: String) {
    FKLogD("[FKImageView] \(message)")
  }
}
