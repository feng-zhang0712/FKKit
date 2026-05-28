import UIKit

@MainActor
enum FKSheetScrollTracking {
  /// Depth-first lookup for the first scroll view in presented content.
  static func findPrimaryScrollView(in root: UIView?) -> UIScrollView? {
    guard let root else { return nil }
    if let scroll = root as? UIScrollView { return scroll }
    for subview in root.subviews {
      if let found = findPrimaryScrollView(in: subview) { return found }
    }
    return nil
  }

  /// Resolves the sheet pan-handoff scroll view based on the selected strategy.
  static func resolvedTrackedScrollView(
    strategy: FKSheetScrollTrackingStrategy,
    in root: UIView?
  ) -> UIScrollView? {
    switch strategy {
    case .automatic:
      return findPrimaryScrollView(in: root)
    case .disabled:
      return nil
    case let .explicit(box):
      return box.object
    }
  }
}
