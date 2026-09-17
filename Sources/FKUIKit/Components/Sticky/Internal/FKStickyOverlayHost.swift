import UIKit

/// Non-scrolling host for stuck sticky targets.
///
/// **Preferred:** sibling of the scroll view on `scrollView.superview`, framed to
/// `scrollView.frame` (viewport in parent coordinates). Rubber-band offset-only changes
/// do not rewrite the host frame — important for `UITableView` near max content offset.
///
/// **Fallback:** subview of the scroll view synced to `contentOffset` + `bounds.size` when
/// the scroll view has no superview yet. ``ensurePreferredHosting(in:)`` reattaches to the
/// parent once one appears.
@MainActor
final class FKStickyOverlayHost: UIView {
  /// Scroll view this host tracks; used to re-sync when the parent lays out.
  private weak var trackedScrollView: UIScrollView?

  /// `true` when hosted as a sibling of the scroll view (preferred path).
  private(set) var isSiblingHosted = false

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

  /// Only claims hits on interactive sticky children so the scroll view underneath stays draggable.
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    subviews.contains { subview in
      !subview.isHidden
        && subview.alpha > 0.01
        && subview.isUserInteractionEnabled
        && subview.point(inside: convert(point, to: subview), with: event)
    }
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard self.point(inside: point, with: event) else { return nil }
    return super.hitTest(point, with: event)
  }

  /// Re-asserts the host frame if layout rewrote it between scroll ticks.
  override func layoutSubviews() {
    if let scrollView = superview as? UIScrollView {
      syncToVisibleBounds(of: scrollView)
    } else if let scrollView = trackedScrollView, superview === scrollView.superview {
      syncToScrollViewFrame(scrollView)
    }
    super.layoutSubviews()
  }

  /// Creates a host and installs it via ``ensurePreferredHosting(in:)``.
  static func install(in scrollView: UIScrollView) -> FKStickyOverlayHost {
    let host = FKStickyOverlayHost(
      frame: CGRect(origin: .zero, size: scrollView.bounds.size)
    )
    host.translatesAutoresizingMaskIntoConstraints = true
    host.autoresizingMask = []
    host.ensurePreferredHosting(in: scrollView)
    return host
  }

  /// Prefers sibling hosting on `scrollView.superview`; falls back to an in-scroll host.
  ///
  /// When already sibling-hosted, only reorders if the host sits below the scroll view —
  /// does **not** `bringSubviewToFront` on every call (that fights bounce layout).
  func ensurePreferredHosting(in scrollView: UIScrollView) {
    trackedScrollView = scrollView

    if let parent = scrollView.superview {
      if superview !== parent {
        removeFromSuperview()
        parent.insertSubview(self, aboveSubview: scrollView)
      } else if needsReorderAboveScrollView(scrollView) {
        parent.insertSubview(self, aboveSubview: scrollView)
      }
      isSiblingHosted = true
      syncToScrollViewFrame(scrollView)
      return
    }

    // No superview yet — temporary in-scroll host (contentOffset-synced).
    if superview !== scrollView {
      removeFromSuperview()
      scrollView.addSubview(self)
    } else {
      scrollView.bringSubviewToFront(self)
    }
    isSiblingHosted = false
    syncToVisibleBounds(of: scrollView)
  }

  /// Syncs the host frame for the active hosting mode.
  ///
  /// Sibling: `scrollView.frame` in the parent (no-op on offset-only rubber-band).
  /// In-scroll fallback: visible bounds in content coordinates.
  func syncToScrollViewFrame(_ scrollView: UIScrollView) {
    trackedScrollView = scrollView
    if isSiblingHosted, scrollView.superview != nil, superview === scrollView.superview {
      let next = scrollView.frame
      guard hostFrameNeedsSync(to: next) else { return }
      frame = next
      return
    }
    syncToVisibleBounds(of: scrollView)
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

  private func needsReorderAboveScrollView(_ scrollView: UIScrollView) -> Bool {
    guard let parent = superview,
          let scrollIndex = parent.subviews.firstIndex(of: scrollView),
          let selfIndex = parent.subviews.firstIndex(of: self)
    else {
      return false
    }
    return selfIndex < scrollIndex
  }

  private func hostFrameNeedsSync(to next: CGRect) -> Bool {
    abs(frame.minX - next.minX) > 0.5
      || abs(frame.minY - next.minY) > 0.5
      || abs(frame.width - next.width) > 0.5
      || abs(frame.height - next.height) > 0.5
  }
}
