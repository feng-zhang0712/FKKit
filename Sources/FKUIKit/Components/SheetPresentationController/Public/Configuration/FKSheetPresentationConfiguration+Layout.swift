import UIKit

public extension FKSheetPresentationConfiguration {
  /// Placement mode and mode-specific sizing behavior.
  public enum Layout {
    /// Bottom-attached sheet with detents, grabber, and swipe-to-resize semantics.
    case bottomSheet(SheetConfiguration)
    /// Top-attached sheet with the same detent model as ``bottomSheet(_:)``.
    case topSheet(SheetConfiguration)
    /// Centered floating modal with fixed or fitted sizing.
    case center(CenterConfiguration)
    /// In-hierarchy anchor popup attached to a source view or rect provider.
    case anchor(FKAnchorConfiguration)
    /// Edge-attached tray that fills one screen edge (left, right, top, or bottom).
    ///
    /// Detent APIs do not apply; the panel uses a fixed edge-based frame from the layout engine.
    case edge(UIRectEdge)
  }
}
