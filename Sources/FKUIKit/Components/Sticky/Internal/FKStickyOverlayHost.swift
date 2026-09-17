import UIKit

/// Non-scrolling host that tracks a scroll view’s visible bounds for stuck targets.
///
/// Frame is synced from ``FKStickyEngine`` using `contentOffset` + `bounds.size` rather than
/// `frameLayoutGuide` constraints. `UITableView` rewrites unconstrained / conflicting subview
/// frames during layout and rubber-banding; guide constraints alone are not reliable there.
@MainActor
final class FKStickyOverlayHost: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true
    backgroundColor = .clear
    accessibilityIdentifier = "fk.sticky.overlay"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Forwards hits that miss child sticky views so scrolling underneath still works.
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    return hit === self ? nil : hit
  }

  /// Re-asserts the visible-bounds frame if `UITableView` / layout rewrote it between scroll ticks.
  override func layoutSubviews() {
    if let scrollView = superview as? UIScrollView {
      syncToVisibleBounds(of: scrollView)
    }
    super.layoutSubviews()
  }

  /// Installs the overlay inside `scrollView` (frame updated by the engine each layout pass).
  static func install(in scrollView: UIScrollView) -> FKStickyOverlayHost {
    let host = FKStickyOverlayHost(
      frame: CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
    )
    host.translatesAutoresizingMaskIntoConstraints = true
    host.autoresizingMask = []
    scrollView.addSubview(host)
    scrollView.bringSubviewToFront(host)
    return host
  }

  /// Keeps the host aligned with the scroll view’s visible rect in **content** coordinates.
  func syncToVisibleBounds(of scrollView: UIScrollView) {
    let next = CGRect(
      x: scrollView.contentOffset.x,
      y: scrollView.contentOffset.y,
      width: scrollView.bounds.width,
      height: scrollView.bounds.height
    )
    guard hostFrameNeedsSync(to: next) else { return }
    frame = next
  }

  private func hostFrameNeedsSync(to next: CGRect) -> Bool {
    abs(frame.minX - next.minX) > 0.5
      || abs(frame.minY - next.minY) > 0.5
      || abs(frame.width - next.width) > 0.5
      || abs(frame.height - next.height) > 0.5
  }
}
