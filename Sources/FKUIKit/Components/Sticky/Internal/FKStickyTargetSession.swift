import CoreGraphics
import UIKit

/// Per-target runtime bookkeeping owned by ``FKStickyEngine``.
@MainActor
final class FKStickyTargetSession {
  let target: FKStickyTarget

  weak var originalSuperview: UIView?
  var originalSiblingIndex: Int = 0
  var naturalContentOrigin: CGPoint = .zero
  /// Frame of the target in ``originalSuperview`` at stick time (preferred restore origin).
  var naturalFrameInSuperview: CGRect = .zero
  var naturalSize: CGSize = .zero
  var placeholder: FKStickyPlaceholderView?
  var state: FKStickyState = .idle
  var progressValue: CGFloat = 0
  var isHostedInOverlay = false
  var capturedShadow: FKStickyShadowCapture?
  var hasCapturedNaturalOrigin = false
  /// Counts layout passes that must keep the target idle after an unstick restore.
  ///
  /// Unstick re-inserts the view into Auto Layout; the next nested `contentSize` KVO can run
  /// before the restored frame settles and would otherwise re-stick with a corrupted origin.
  var suppressStickForPasses: Int = 0
  /// Captured when first sticking so Autolayout flags can be restored on unstick.
  var usesAutoresizingMask = true
  /// `true` when the target was an arranged subview of a ``UIStackView``.
  var isArrangedInStack = false
  /// Index in `UIStackView.arrangedSubviews` when ``isArrangedInStack`` is `true`.
  var arrangedStackIndex: Int = 0
  /// `true` when the target should span the scroll viewport (minus leading inset) while stuck.
  ///
  /// Set for vertical ``UIStackView`` + `.fill` parents. Avoids freezing a collapsed intrinsic
  /// width into overlay layout.
  var fillsViewportWidth = false
  /// Target-owned width/height constraints deactivated while frame-hosted in the overlay.
  ///
  /// Leaving them active alongside overlay layout lets Auto Layout recover the view to its
  /// intrinsic (label) width after each frame assignment.
  var deactivatedSizeConstraints: [NSLayoutConstraint] = []
  /// Ensures ``FKStickyEngine`` only scans for target-owned size constraints once per stick.
  ///
  /// Frame-based targets often have none; without this flag the next scroll tick would treat
  /// the engine’s own overlay height constraint as “target-owned” and deactivate it, collapsing
  /// the stuck strip to zero height while progress still reports `sticking` / `stuck`.
  var didPrepareFrameHosting = false
  /// Engine-owned overlay placement constraints.
  var overlayLeadingConstraint: NSLayoutConstraint?
  var overlayTrailingConstraint: NSLayoutConstraint?
  var overlayTopConstraint: NSLayoutConstraint?
  var overlayWidthConstraint: NSLayoutConstraint?
  var overlayHeightConstraint: NSLayoutConstraint?
  /// Width constraint on the placeholder when using Auto Layout sizing.
  var placeholderWidthConstraint: NSLayoutConstraint?
  /// Height constraint on the placeholder when using Auto Layout sizing.
  var placeholderHeightConstraint: NSLayoutConstraint?

  init(target: FKStickyTarget) {
    self.target = target
  }
}

/// Original layer shadow values restored when unsticking if the engine applied a stuck shadow.
struct FKStickyShadowCapture {
  var opacity: Float
  var radius: CGFloat
  var offset: CGSize
  var color: CGColor?
  var path: CGPath?
}
