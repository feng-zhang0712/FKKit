import UIKit

/// Layout hints for ``FKImageView`` intrinsic sizing.
public struct FKImageViewLayoutConfiguration: Equatable, Sendable {
  /// Hint used for intrinsic content size when no image is loaded.
  public var intrinsicPlaceholderSize: CGSize?

  /// Creates layout defaults.
  public init(intrinsicPlaceholderSize: CGSize? = nil) {
    self.intrinsicPlaceholderSize = intrinsicPlaceholderSize
  }
}
