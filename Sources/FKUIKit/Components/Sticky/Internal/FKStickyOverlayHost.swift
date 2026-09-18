import UIKit

/// Non-scrolling host for stuck sticky targets.
///
/// **Preferred:** sibling of the scroll view on `scrollView.superview`, pinned to the
/// scroll view’s edges. Those anchors follow `scrollView.frame` and do not change when
/// only `contentOffset` rubber-bands — important for `UITableView` near max content offset.
///
/// **Fallback:** subview of the scroll view, pinned to ``UIScrollView/frameLayoutGuide``,
/// when the scroll view has no superview yet. ``ensurePreferredHosting(in:)`` reattaches
/// to the parent once one appears.
///
/// The host is not frame-positioned. A translated autoresizing-mask width of `0` (before
/// the first layout pass) conflicts with required edge constraints on stuck content.
@MainActor
final class FKStickyOverlayHost: UIView {
  /// Identifier for edge pins so they can be replaced without retaining the scroll view.
  private static let edgeConstraintIdentifier = "fk.sticky.overlay.edge"

  /// Scroll view this host tracks; used to re-pin when the parent changes.
  private weak var trackedScrollView: UIScrollView?

  /// `true` when hosted as a sibling of the scroll view (preferred path).
  private(set) var isSiblingHosted = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    // Must be false before the host enters an Auto Layout hierarchy. The default
    // `true` installs `width == 0` while the frame is still empty.
    translatesAutoresizingMaskIntoConstraints = false
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

  /// Creates a host and installs it via ``ensurePreferredHosting(in:)``.
  static func install(in scrollView: UIScrollView) -> FKStickyOverlayHost {
    let host = FKStickyOverlayHost(frame: .zero)
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
        deactivateEdgeConstraints()
        removeFromSuperview()
        parent.insertSubview(self, aboveSubview: scrollView)
      } else if needsReorderAboveScrollView(scrollView) {
        parent.insertSubview(self, aboveSubview: scrollView)
      }
      isSiblingHosted = true
      if !isPinned(to: scrollView, sibling: true) {
        pinToScrollViewFrame(scrollView)
      }
      return
    }

    // No superview yet — temporary in-scroll host (frameLayoutGuide, not contentOffset).
    if superview !== scrollView {
      deactivateEdgeConstraints()
      removeFromSuperview()
      scrollView.addSubview(self)
    } else {
      scrollView.bringSubviewToFront(self)
    }
    isSiblingHosted = false
    if !isPinned(to: scrollView, sibling: false) {
      pinToFrameLayoutGuide(of: scrollView)
    }
  }

  /// Keeps the host matched to the scroll view’s visible frame.
  ///
  /// Sibling and in-scroll pins already track that frame, so this does not write `frame`
  /// on offset-only rubber-band ticks.
  func syncToScrollViewFrame(_ scrollView: UIScrollView) {
    ensurePreferredHosting(in: scrollView)
  }

  private func pinToScrollViewFrame(_ scrollView: UIScrollView) {
    replaceEdgeConstraints([
      leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      topAnchor.constraint(equalTo: scrollView.topAnchor),
      bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
    ])
  }

  private func pinToFrameLayoutGuide(of scrollView: UIScrollView) {
    let guide = scrollView.frameLayoutGuide
    replaceEdgeConstraints([
      leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      topAnchor.constraint(equalTo: guide.topAnchor),
      bottomAnchor.constraint(equalTo: guide.bottomAnchor),
    ])
  }

  private func replaceEdgeConstraints(_ constraints: [NSLayoutConstraint]) {
    deactivateEdgeConstraints()
    for constraint in constraints {
      constraint.identifier = Self.edgeConstraintIdentifier
    }
    NSLayoutConstraint.activate(constraints)
  }

  /// Active edge pins live on the superview (common ancestor), not on this host.
  private func deactivateEdgeConstraints() {
    guard let parent = superview else { return }
    let matching = parent.constraints.filter { constraint in
      constraint.identifier == Self.edgeConstraintIdentifier && (constraint.firstItem as? UIView) === self
    }
    NSLayoutConstraint.deactivate(matching)
  }

  private func isPinned(to scrollView: UIScrollView, sibling: Bool) -> Bool {
    guard let parent = superview else { return false }
    let pins = parent.constraints.filter { constraint in
      constraint.isActive
        && constraint.identifier == Self.edgeConstraintIdentifier
        && (constraint.firstItem as? UIView) === self
    }
    guard pins.count == 4 else { return false }
    if sibling {
      return pins.allSatisfy { ($0.secondItem as? UIView) === scrollView }
    }
    return pins.allSatisfy { ($0.secondItem as? UILayoutGuide) === scrollView.frameLayoutGuide }
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
}
