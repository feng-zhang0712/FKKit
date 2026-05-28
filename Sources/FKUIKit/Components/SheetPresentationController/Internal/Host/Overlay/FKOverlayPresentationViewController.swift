import UIKit

/// Overlay-based presentation container that supports passthrough outside the popup.
@MainActor
final class FKOverlayPresentationViewController: UIViewController, UIGestureRecognizerDelegate {
  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?
  var onSelectedDetentDidChange: ((FKSheetPresentationDetent, Int) -> Void)?

  let configuration: FKSheetPresentationConfiguration

  let rootView = FKOverlayRootView()
  let backdropView = FKSheetPresentationBackdropView()
  let wrapperView = UIView()
  let contentContainerView = UIView()

  lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  weak var hostedContentView: UIView?

  var resolvedDetentHeights: [CGFloat] = []
  var selectedDetentIndex: Int = 0
  var lastBoundsSize: CGSize = .zero
  var skipsDismissPresentationAnimation = false

  let sheetPanCoordinator = FKSheetPresentationSheetPanCoordinator()
  let centerPanCoordinator = FKSheetPresentationCenterPanCoordinator()

  var isPanningSheet: Bool { sheetPanCoordinator.isPanningSheet }
  var isCenterInteractivelyDragging: Bool { centerPanCoordinator.isInteractivelyDragging }

  init(configuration: FKSheetPresentationConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func loadView() {
    view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    backdropView.frame = view.bounds
    backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backdropView.configure(with: configuration.backdropStyle)
    view.addSubview(backdropView)

    wrapperView.backgroundColor = .systemBackground
    wrapperView.addSubview(contentContainerView)

    contentContainerView.backgroundColor = .clear
    contentContainerView.clipsToBounds = true

    view.addSubview(wrapperView)

    installGestures()
    recalculateDetentsIfNeeded()
    selectedDetentIndex = configuration.sheet.initialSelectedDetentIndex
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let newBoundsSize = view.bounds.size
    let boundsChanged = lastBoundsSize != .zero && newBoundsSize != lastBoundsSize
    defer { lastBoundsSize = newBoundsSize }

    guard !sheetPanCoordinator.isPanningSheet, !centerPanCoordinator.isInteractivelyDragging, boundsChanged else {
      updatePassthroughHitTesting()
      return
    }

    switch configuration.rotationHandling {
    case .ignore:
      updatePassthroughHitTesting()
    case .relayoutImmediate, .relayoutAnimated:
      recalculateDetentsIfNeeded()
      let applyLayout = {
        self.wrapperView.frame = self.frameOfWrapper()
        self.layoutContent()
        self.applyAppearance()
        self.updatePassthroughHitTesting()
      }
      if configuration.rotationHandling == .relayoutAnimated {
        UIView.animate(
          withDuration: 0.32,
          delay: 0,
          options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
          animations: applyLayout
        )
      } else {
        applyLayout()
      }
    }
  }

  func publishInitialSelectedDetentIfNeeded() {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      recalculateDetentsIfNeeded()
      guard configuration.sheet.detents.indices.contains(selectedDetentIndex) else { return }
      onSelectedDetentDidChange?(configuration.sheet.detents[selectedDetentIndex], selectedDetentIndex)
    default:
      break
    }
    if configuration.accessibility.announcesScreenChange {
      UIAccessibility.post(notification: .screenChanged, argument: configuration.accessibility.announcement)
    }
  }

  /// Returns whether an interactive dismiss already animated off-screen and clears the latch.
  func consumeSkipsDismissPresentationAnimation() -> Bool {
    defer { skipsDismissPresentationAnimation = false }
    return skipsDismissPresentationAnimation
  }
}

final class FKOverlayRootView: UIView {
  var interactiveRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    interactiveRect.contains(point)
  }
}
