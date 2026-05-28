import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Owner Callbacks

  /// Forwards live interactive progress to the public controller hooks.
  func notifyProgress(_ progress: CGFloat) {
    owner?.notifyProgress(progress)
  }

  /// Forwards detent transitions to delegate/handler pipelines.
  func notifySelectedDetentDidChange(_ detent: FKSheetPresentationDetent, index: Int) {
    owner?.notifySelectedDetentDidChange(detent, index: index)
  }

  /// Publishes the initial selected detent after presentation completes.
  func publishInitialSelectedDetentIfNeeded() {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      recalculateDetentsIfNeeded()
      guard configuration.sheet.detents.indices.contains(selectedDetentIndex) else { return }
      notifySelectedDetentDidChange(configuration.sheet.detents[selectedDetentIndex], index: selectedDetentIndex)
    default:
      break
    }
  }
}
