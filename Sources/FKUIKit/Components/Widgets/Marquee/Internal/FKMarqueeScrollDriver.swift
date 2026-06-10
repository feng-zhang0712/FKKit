import UIKit

/// Internal CADisplayLink driver for smooth marquee scrolling.
@MainActor
final class FKMarqueeScrollDriver: NSObject {
  nonisolated(unsafe) private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval?
  var onFrame: ((TimeInterval) -> Void)?

  var isRunning: Bool { displayLink != nil }

  func start() {
    guard displayLink == nil else { return }
    lastTimestamp = nil
    let link = CADisplayLink(target: self, selector: #selector(handleTick(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func stop() {
    invalidateDisplayLink()
    lastTimestamp = nil
  }

  /// Safe to call from `nonisolated` teardown (e.g. host view `deinit`).
  nonisolated func tearDown() {
    displayLink?.invalidate()
    displayLink = nil
  }

  private func invalidateDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func handleTick(_ link: CADisplayLink) {
    if let lastTimestamp {
      let delta = link.timestamp - lastTimestamp
      if delta > 0 {
        onFrame?(delta)
      }
    }
    lastTimestamp = link.timestamp
  }

  nonisolated deinit {
    displayLink?.invalidate()
  }
}