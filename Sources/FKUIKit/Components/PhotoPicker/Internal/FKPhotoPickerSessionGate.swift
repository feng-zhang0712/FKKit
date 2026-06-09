import UIKit

/// Ensures a pick-session continuation resumes exactly once.
@MainActor
final class FKPhotoPickerSessionGate {
  private var continuation: CheckedContinuation<Void, Error>?
  private var hasResumed = false
  private var dismissObserver: FKPhotoPickerDismissObserver?

  func bind(
    continuation: CheckedContinuation<Void, Error>,
    to presentedController: UIViewController,
    onExternalDismiss: @escaping () -> Void
  ) {
    self.continuation = continuation
    let observer = FKPhotoPickerDismissObserver {
      onExternalDismiss()
    }
    dismissObserver = observer
    presentedController.presentationController?.delegate = observer
  }

  func complete() {
    resumeOnce()
  }

  func cancel() {
    resumeOnce(throwing: FKPhotoPickerError.cancelled)
  }

  func fail(with error: Error) {
    guard !hasResumed else { return }
    hasResumed = true
    dismissObserver = nil
    continuation?.resume(throwing: error)
    continuation = nil
  }

  func invalidate() {
    hasResumed = true
    continuation = nil
    dismissObserver = nil
  }

  private func resumeOnce(throwing error: FKPhotoPickerError? = nil) {
    guard !hasResumed else { return }
    hasResumed = true
    dismissObserver = nil
    if let error {
      continuation?.resume(throwing: error)
    } else {
      continuation?.resume()
    }
    continuation = nil
  }
}

/// Detects interactive or programmatic sheet/popover dismissal before picker delegates fire.
@MainActor
final class FKPhotoPickerDismissObserver: NSObject, UIAdaptivePresentationControllerDelegate {
  private let onDismiss: () -> Void

  init(onDismiss: @escaping () -> Void) {
    self.onDismiss = onDismiss
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    onDismiss()
  }
}
