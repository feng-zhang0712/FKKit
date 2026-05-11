import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Owner Callbacks

  /// Forwards live interactive progress to the public controller hooks.
  func notifyProgress(_ progress: CGFloat) {
    owner?.notifyProgress(progress)
  }

  /// Forwards detent transitions to delegate/handler pipelines.
  func notifySelectedDetentDidChange(_ detent: FKPresentationDetent, index: Int) {
    owner?.notifySelectedDetentDidChange(detent, index: index)
  }
}
