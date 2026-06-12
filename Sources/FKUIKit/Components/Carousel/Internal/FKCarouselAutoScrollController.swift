import UIKit

/// Timer-driven auto-scroll with pause rules.
final class FKCarouselAutoScrollController: @unchecked Sendable {
  typealias AdvanceHandler = (_ from: Int, _ to: Int) -> Bool

  private weak var timerTarget: TimerTarget?
  private var timer: Timer?
  private var isPaused = false

  var configuration: FKCarouselAutoScrollConfiguration = .init()
  var pageCount: Int = 0
  var currentPageIndex: Int = 0
  var isUserInteracting = false
  var isVisible = true
  var isAppActive = true
  var onAdvance: AdvanceHandler?

  deinit {
    invalidateTimer()
  }

  func invalidateTimer() {
    timer?.invalidate()
    timer = nil
  }

  func refreshTimerState() {
    guard shouldRun else {
      invalidateTimer()
      return
    }

    if timer == nil {
      let target = TimerTarget { [weak self] in
        self?.handleTimerFire()
      }
      timerTarget = target
      let newTimer = Timer(
        timeInterval: max(0.1, configuration.interval),
        target: target,
        selector: #selector(TimerTarget.fire),
        userInfo: nil,
        repeats: configuration.repeats
      )
      RunLoop.main.add(newTimer, forMode: .common)
      timer = newTimer
    }
  }

  func resetIntervalAfterManualChange() {
    guard shouldRun else { return }
    invalidateTimer()
    refreshTimerState()
  }

  private var shouldRun: Bool {
    guard configuration.isEnabled else { return false }
    guard pageCount > 1 else { return false }
    if configuration.pausesWhenOffscreen, !isVisible { return false }
    if configuration.pausesWhenAppInactive, !isAppActive { return false }
    if configuration.pausesOnUserInteraction, isUserInteracting { return false }
    if configuration.respectsReducedMotion, UIAccessibility.isReduceMotionEnabled { return false }
    return true
  }

  private func handleTimerFire() {
    guard pageCount > 1 else {
      invalidateTimer()
      return
    }

    let from = currentPageIndex
    let to: Int
    switch configuration.direction {
    case .forward:
      to = (from + 1) % pageCount
      if to == 0, !configuration.repeats, from == pageCount - 1 {
        invalidateTimer()
        return
      }
    case .reverse:
      to = from == 0 ? pageCount - 1 : from - 1
      if to == pageCount - 1, !configuration.repeats, from == 0 {
        invalidateTimer()
        return
      }
    }

    guard onAdvance?(from, to) ?? true else { return }
  }
}

private final class TimerTarget: NSObject {
  private let handler: () -> Void

  init(handler: @escaping () -> Void) {
    self.handler = handler
  }

  @objc func fire() {
    handler()
  }
}
