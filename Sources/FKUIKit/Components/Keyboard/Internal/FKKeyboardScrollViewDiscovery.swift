import UIKit

/// Discovers a suitable `UIScrollView` for content-inset keyboard avoidance.
@MainActor
enum FKKeyboardScrollViewDiscovery {
  /// Depth-first search preferring larger visible scroll views.
  static func findPrimaryScrollView(in root: UIView?) -> UIScrollView? {
    guard let root else { return nil }
    var best: UIScrollView?
    var bestArea: CGFloat = 0

    func visit(_ view: UIView) {
      if let scroll = view as? UIScrollView, scroll.window != nil, !scroll.isHidden, scroll.alpha > 0.01 {
        let area = scroll.bounds.width * scroll.bounds.height
        if area >= bestArea {
          bestArea = area
          best = scroll
        }
      }
      for sub in view.subviews {
        visit(sub)
      }
    }

    visit(root)
    return best
  }
}
