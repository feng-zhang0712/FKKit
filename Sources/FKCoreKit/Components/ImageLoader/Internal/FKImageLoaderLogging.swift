import Foundation

enum FKImageLoaderLogging {
  static func debug(_ configuration: FKImageLoaderConfiguration, _ message: String) {
    guard configuration.isLoggingEnabled else { return }
    FKLogD("[FKImageLoader] \(message)")
  }
}
