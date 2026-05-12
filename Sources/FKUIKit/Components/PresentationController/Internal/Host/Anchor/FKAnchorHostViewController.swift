import UIKit

/// Internal view controller used by `FKAnchorHost`.
///
/// Responsibilities:
/// - Hosts the anchor presentation root view (mask/backdrop + content container)
/// - Installs gestures (tap to dismiss, pan to dismiss)
/// - Exposes a single layout update entry point
@MainActor
final class FKAnchorHostViewController: UIViewController {
  struct MaskStyle {
    var alpha: CGFloat
  }

  struct Layout {
    var hostBounds: CGRect
    var presentationFrame: CGRect
    var maskCoverageRect: CGRect
    var anchorLineY: CGFloat
    var direction: FKAnchor.Direction
  }

  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?

  private let configuration: FKPresentationConfiguration

  let contentContainerView = UIView()
  /// Inner card that clips content to rounded corners (shadow lives on `wrapperView`, which must not clip).
  private let cardView = UIView()
  /// Optional blur material rendered behind anchor content (installed only when `configuration.containerBlur.isEnabled`).
  private var containerBlurView: FKBlurView?
  /// Presentation shell: carries frame, shadow, and pan gesture; hosts `cardView` as direct subview.
  let wrapperView = UIView()

  private let maskView = FKAnchorMaskView()
  private lazy var tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(handleTapMask(_:)))
  private lazy var panToDismiss = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

  private var panStartFrame: CGRect = .zero
  private var currentLayout: Layout?

  private var rootView: FKAnchorRootView {
    view as! FKAnchorRootView
  }

  init(configuration: FKPresentationConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func loadView() {
    view = FKAnchorRootView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    // Mask/backdrop
    maskView.backgroundColor = maskColor()
    maskView.alpha = 0
    view.addSubview(maskView)

    // Wrapper + card: shadow on `wrapperView` (must not clip); corner + clip on `cardView`.
    wrapperView.backgroundColor = .clear
    wrapperView.layer.masksToBounds = false
    wrapperView.layer.fk_applyShadow(configuration.shadow, path: nil)

    cardView.backgroundColor = .systemBackground
    cardView.layer.cornerRadius = configuration.cornerRadius
    cardView.layer.masksToBounds = true

    cardView.layer.fk_applyBorder(configuration.border)

    contentContainerView.backgroundColor = .clear

    cardView.addSubview(contentContainerView)
    wrapperView.addSubview(cardView)
    view.addSubview(wrapperView)

    // Gestures
    if configuration.dismissBehavior.allowsTapOutside {
      maskView.isUserInteractionEnabled = true
      maskView.addGestureRecognizer(tapToDismiss)
    } else {
      maskView.isUserInteractionEnabled = false
    }

    if configuration.dismissBehavior.allowsSwipe {
      panToDismiss.maximumNumberOfTouches = 1
      wrapperView.addGestureRecognizer(panToDismiss)
    }

    configureContainerBlurIfNeeded()
  }

  var currentPresentationFrame: CGRect { wrapperView.frame }

  func applyLayout(_ layout: Layout) {
    currentLayout = layout
    maskView.frame = layout.hostBounds
    maskView.coverageRect = layout.maskCoverageRect

    wrapperView.frame = layout.presentationFrame
    cardView.frame = wrapperView.bounds
    containerBlurView?.frame = cardView.bounds
    contentContainerView.frame = cardView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))

    // Corner strategy: keep the attached edge “straight” to avoid a modal-card feel.
    switch layout.direction {
    case .down:
      cardView.layer.maskedCorners = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    case .up:
      cardView.layer.maskedCorners = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
      ]
    case .auto:
      cardView.layer.maskedCorners = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    }
    updateBlurMask(for: layout.direction)

    // Shadow strategy: follow the free edge (bottom for below, top for above).
    updateShadowPath(for: layout.direction)

    // Keep host view transparent to touches outside interactive zones.
    rootView.interactiveRect = layout.maskCoverageRect.union(layout.presentationFrame)
  }

  func animateMaskAlpha(_ alpha: CGFloat) {
    maskView.alpha = alpha
  }

  private func maskColor() -> UIColor {
    // Keep anchor mask aligned with the configured backdrop dim when possible.
    switch configuration.backdropStyle {
    case let .dim(color, alpha):
      return color.withAlphaComponent(alpha)
    default:
      return UIColor.black.withAlphaComponent(0.35)
    }
  }

  private func updateShadowPath(for direction: FKAnchor.Direction) {
    let radius: CGFloat
    switch configuration.shadow {
    case .none:
      wrapperView.layer.shadowOpacity = 0
      wrapperView.layer.shadowPath = nil
      return
    case .custom(_, let opacity, let r, _) where opacity > 0 && r > 0:
      radius = r
    default:
      wrapperView.layer.shadowOpacity = 0
      wrapperView.layer.shadowPath = nil
      return
    }

    let b = cardView.bounds
    let stripThickness = max(2, radius * 2)
    let rect: CGRect = {
      switch direction {
      case .down:
        return CGRect(x: 0, y: b.maxY - stripThickness, width: b.width, height: stripThickness + radius * 2)
      case .up:
        return CGRect(x: 0, y: -radius * 2, width: b.width, height: stripThickness + radius * 2)
      case .auto:
        return CGRect(x: 0, y: b.maxY - stripThickness, width: b.width, height: stripThickness + radius * 2)
      }
    }()
    wrapperView.layer.shadowPath = UIBezierPath(rect: rect).cgPath
  }

  private func configureContainerBlurIfNeeded() {
    let blur = configuration.containerBlur
    guard blur.isEnabled else {
      containerBlurView?.blurSourceView = nil
      containerBlurView?.maskPath = nil
      containerBlurView?.removeFromSuperview()
      containerBlurView = nil
      cardView.backgroundColor = .systemBackground
      return
    }

    let blurView: FKBlurView
    if let existing = containerBlurView {
      blurView = existing
    } else {
      let v = FKBlurView()
      v.isUserInteractionEnabled = false
      cardView.insertSubview(v, belowSubview: contentContainerView)
      containerBlurView = v
      blurView = v
    }
    blurView.isHidden = false
    blurView.configuration = blur.configuration
    blurView.blurSourceView = presentingViewController?.view
    cardView.backgroundColor = .clear
  }

  private func updateBlurMask(for direction: FKAnchor.Direction) {
    guard let containerBlurView, !containerBlurView.isHidden else { return }
    let radius = max(0, configuration.cornerRadius)
    guard radius > 0 else {
      containerBlurView.maskPath = nil
      return
    }
    let roundedCorners: UIRectCorner = {
      switch direction {
      case .down:
        // Cancel top-left / top-right corners (attached edge is straight).
        return [.bottomLeft, .bottomRight]
      case .up:
        return [.topLeft, .topRight]
      case .auto:
        return [.bottomLeft, .bottomRight]
      }
    }()
    containerBlurView.maskPath = UIBezierPath(
      roundedRect: containerBlurView.bounds,
      byRoundingCorners: roundedCorners,
      cornerRadii: .init(width: radius, height: radius)
    )
  }

  @objc private func handleTapMask(_ recognizer: UITapGestureRecognizer) {
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    onRequestDismiss?()
  }

  @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.dismissBehavior.allowsSwipe else { return }
    guard let currentLayout else { return }
    let translation = recognizer.translation(in: view)

    switch recognizer.state {
    case .began:
      panStartFrame = wrapperView.frame
    case .changed:
      let signedDismissDrag: CGFloat = {
        // When expanding down from anchor, dismiss by dragging up (towards the anchor line).
        // When expanding up, dismiss by dragging down.
        switch currentLayout.direction {
        case .down: return -translation.y
        case .up: return translation.y
        case .auto: return -translation.y
        }
      }()

      let panelHeight = max(1, panStartFrame.height)
      // Keep height fixed; slide along Y (same end poses as the old height-collapse path).
      let slide = min(max(signedDismissDrag, 0), panelHeight)
      let newY: CGFloat = {
        switch currentLayout.direction {
        case .down, .auto:
          return panStartFrame.origin.y - slide
        case .up:
          return panStartFrame.origin.y + slide
        }
      }()
      var newFrame = panStartFrame
      newFrame.origin.y = newY
      newFrame.size.height = panelHeight
      wrapperView.frame = newFrame
      cardView.frame = wrapperView.bounds
      contentContainerView.frame = cardView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))
      updateShadowPath(for: currentLayout.direction)

      let progress = min(max(slide / panelHeight, 0), 1)
      onProgress?(progress)
      maskView.alpha = max(0, 1 - progress)
    case .ended, .cancelled:
      let velocity = recognizer.velocity(in: view).y
      let panelHeight = max(1, panStartFrame.height)
      let slideAmount: CGFloat = {
        switch currentLayout.direction {
        case .down, .auto:
          return panStartFrame.origin.y - wrapperView.frame.origin.y
        case .up:
          return wrapperView.frame.origin.y - panStartFrame.origin.y
        }
      }()
      let progress = min(max(slideAmount / panelHeight, 0), 1)

      let shouldDismiss: Bool = {
        if progress > 0.35 { return true }
        let dismissVelocity: CGFloat = {
          switch currentLayout.direction {
          case .down: return -velocity
          case .up: return velocity
          case .auto: return -velocity
          }
        }()
        return dismissVelocity > 900
      }()
      if shouldDismiss {
        onRequestDismiss?()
      } else {
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
          self.wrapperView.frame = self.panStartFrame
          self.cardView.frame = self.wrapperView.bounds
          self.contentContainerView.frame = self.cardView.bounds.inset(by: UIEdgeInsets(self.configuration.contentInsets))
          self.updateShadowPath(for: currentLayout.direction)
          self.maskView.alpha = 1
        } completion: { _ in
          self.onProgress?(0)
        }
      }
    default:
      break
    }
  }
}

private final class FKAnchorMaskView: UIView {
  var coverageRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    coverageRect.contains(point)
  }
}

private final class FKAnchorRootView: UIView {
  var interactiveRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    interactiveRect.contains(point)
  }
}

