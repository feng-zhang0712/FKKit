import Foundation

@MainActor
final class FKPagingStateMachine {
  private(set) var snapshot: FKPagingStateSnapshot

  init(initialIndex: Int) {
    snapshot = FKPagingStateSnapshot(selectedIndex: max(0, initialIndex))
  }

  @discardableResult
  func beginProgrammaticSwitch(from: Int, to: Int) -> Int {
    snapshot.transitionToken &+= 1
    snapshot.phase = .programmaticSwitch
    snapshot.fromIndex = from
    snapshot.toIndex = to
    snapshot.progress = 0
    return snapshot.transitionToken
  }

  func beginDragging(from: Int, to: Int) {
    snapshot.phase = .dragging
    snapshot.fromIndex = from
    snapshot.toIndex = to
    snapshot.progress = 0
  }

  func updateDraggingProgress(_ progress: CGFloat, from: Int, to: Int) {
    if snapshot.phase != .dragging {
      beginDragging(from: from, to: to)
    }
    snapshot.fromIndex = from
    snapshot.toIndex = to
    snapshot.progress = max(0, min(1, progress))
  }

  func beginSettling() {
    snapshot.phase = .settling
  }

  func settle(at index: Int) {
    snapshot.selectedIndex = index
    snapshot.phase = .idle
    snapshot.fromIndex = nil
    snapshot.toIndex = nil
    snapshot.progress = 0
  }

  func interrupt() {
    snapshot.phase = .interrupted
    snapshot.fromIndex = nil
    snapshot.toIndex = nil
    snapshot.progress = 0
  }
}
