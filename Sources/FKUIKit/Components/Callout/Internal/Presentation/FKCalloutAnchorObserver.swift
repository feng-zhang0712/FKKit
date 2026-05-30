import UIKit

/// Observes anchor layout changes and dismisses when the anchor leaves the visible hierarchy.
@MainActor
final class FKCalloutAnchorObserver: NSObject {
  private weak var anchorView: UIView?
  private weak var hostViewController: UIViewController?
  private var pollTimer: Timer?
  private var pendingRelayout: DispatchWorkItem?
  private var lastAnchorRectInWindow: CGRect = .null
  private var didReportUnavailable = false
  private let onRelayout: () -> Void
  private let onAnchorUnavailable: () -> Void
  private let pollInterval: TimeInterval = 1.0 / 30.0
  private let relayoutDebounceInterval: TimeInterval = 1.0 / 60.0

  init(
    anchorView: UIView,
    onRelayout: @escaping () -> Void,
    onAnchorUnavailable: @escaping () -> Void
  ) {
    self.anchorView = anchorView
    self.hostViewController = anchorView.fk_nearestViewController
    self.onRelayout = onRelayout
    self.onAnchorUnavailable = onAnchorUnavailable
    super.init()
    if let window = anchorView.window {
      lastAnchorRectInWindow = anchorView.convert(anchorView.bounds, to: window)
    }
    start()
  }

  func invalidate() {
    pollTimer?.invalidate()
    pollTimer = nil
    pendingRelayout?.cancel()
    pendingRelayout = nil
  }

  private func start() {
    let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.tick()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    pollTimer = timer
  }

  private func reportUnavailableIfNeeded() {
    guard !didReportUnavailable else { return }
    didReportUnavailable = true
    invalidate()
    onAnchorUnavailable()
  }

  private func scheduleRelayout() {
    pendingRelayout?.cancel()
    let item = DispatchWorkItem { [weak self] in
      self?.onRelayout()
    }
    pendingRelayout = item
    DispatchQueue.main.asyncAfter(deadline: .now() + relayoutDebounceInterval, execute: item)
  }

  private func tick() {
    guard let anchorView else {
      reportUnavailableIfNeeded()
      return
    }

    if let host = hostViewController, host.isBeingDismissed || host.isMovingFromParent {
      reportUnavailableIfNeeded()
      return
    }

    guard let window = anchorView.window else {
      reportUnavailableIfNeeded()
      return
    }

    if anchorView.isHidden || anchorView.alpha < 0.01 {
      reportUnavailableIfNeeded()
      return
    }

    let rect = anchorView.convert(anchorView.bounds, to: window)
    guard rect != lastAnchorRectInWindow else { return }
    lastAnchorRectInWindow = rect
    scheduleRelayout()
  }
}
