import UIKit

/// In-hierarchy overlay host used to enable true touch passthrough outside the popup.
///
/// This host is selected for advanced passthrough scenarios because UIKit's modal presentation container
/// always sits above the presenting view controller and cannot forward touches outside the presented view.
@MainActor
final class FKOverlayPresentationHost: NSObject, FKSheetPresentationHost {
  private unowned let owner: FKSheetPresentationController
  private let contentController: UIViewController
  private let configuration: FKSheetPresentationConfiguration

  private var overlayViewController: FKOverlayPresentationViewController?

  private(set) var isPresented: Bool = false

  init(owner: FKSheetPresentationController, contentController: UIViewController, configuration: FKSheetPresentationConfiguration) {
    self.owner = owner
    self.contentController = contentController
    self.configuration = configuration
    super.init()
  }

  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    guard !isPresented else { completion?(); return }

    let parent = presentingViewController
    let overlayVC = FKOverlayPresentationViewController(configuration: configuration)
    overlayVC.onRequestDismiss = { [weak self] in
      self?.owner.dismiss(animated: true, completion: nil)
    }
    overlayVC.onProgress = { [weak self] progress in
      self?.owner.notifyProgress(progress)
    }
    overlayVC.onSelectedDetentDidChange = { [weak self] detent, index in
      self?.owner.notifySelectedDetentDidChange(detent, index: index)
    }

    parent.addChild(overlayVC)
    parent.view.addSubview(overlayVC.view)
    overlayVC.view.frame = parent.view.bounds
    overlayVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlayVC.didMove(toParent: parent)

    overlayViewController = overlayVC
    isPresented = true

    overlayVC.embedContent(contentController)
    overlayVC.updateLayout(animated: false, duration: 0, options: .curveLinear)

    overlayVC.animatePresentation(isPresentation: true, animated: animated) { [weak self] in
      overlayVC.publishInitialSelectedDetentIfNeeded()
      completion?()
      self?.isPresented = true
    }
  }

  func dismiss(animated: Bool, completion: (() -> Void)?) {
    guard isPresented else { completion?(); return }
    isPresented = false

    guard let overlayVC = overlayViewController else {
      completion?()
      cleanup()
      return
    }

    overlayVC.animatePresentation(isPresentation: false, animated: animated) { [weak self] in
      self?.cleanup()
      completion?()
    }
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    overlayViewController?.updateLayout(animated: animated, duration: duration, options: options)
  }

  func selectDetent(at index: Int, animated: Bool) {
    overlayViewController?.selectDetent(at: index, animated: animated)
  }

  func selectDetent(_ detent: FKSheetPresentationDetent, animated: Bool) {
    overlayViewController?.selectDetent(detent, animated: animated)
  }

  private func cleanup() {
    guard let overlayVC = overlayViewController else { return }
    if contentController.parent === overlayVC {
      contentController.willMove(toParent: nil)
      contentController.view.removeFromSuperview()
      contentController.removeFromParent()
    }
    overlayVC.willMove(toParent: nil)
    overlayVC.view.removeFromSuperview()
    overlayVC.removeFromParent()

    overlayViewController = nil
  }
}

