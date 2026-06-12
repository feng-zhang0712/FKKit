import UIKit

/// Icon content for a flow node.
///
/// Prefer ``systemName(_:)`` or ``imageAsset(name:bundle:)`` to keep models thread-safe.
/// ``template(_:)`` requires main-thread construction; use asset names when possible.
public enum FKFlowStepIcon: @unchecked Sendable, Equatable {
  /// One-based index rendered inside the node.
  case number(Int)
  /// SF Symbol name rendered as a template image.
  case systemName(String)
  /// Named image from a bundle.
  case imageAsset(name: String, bundle: Bundle?)
  /// Pre-built template image (main thread).
  case template(UIImage)
  /// Minimal dot node with no glyph.
  case none
}
