import UIKit

/// Helpers for ``FKPopover/show(customView:)`` demos.
enum FKCalloutExampleCustomContent {
  /// Fixed-width wrapper for reliable callout sizing (see ``FKCalloutExampleUI/wrappingCustomContent(_:width:)``).
  static func wrapping(_ content: UIView, width: CGFloat) -> UIView {
    FKCalloutExampleUI.wrappingCustomContent(content, width: width)
  }
}
