import Foundation

/// Describes what ``UIViewController/preferredContentSize`` height represents for sheet fit-content sizing.
public enum FKPreferredContentSizeReporting: Sendable, Equatable {
  /// ``preferredContentSize.height`` is the presentation shell (detent) height — historical default.
  case shellHeight
  /// ``preferredContentSize.height`` is pure hosted content height; FKSheet adds grabber and safe-area compensation.
  case contentOnly
}
