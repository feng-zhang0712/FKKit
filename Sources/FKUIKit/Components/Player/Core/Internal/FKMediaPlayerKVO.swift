import AVFoundation
import Foundation

/// Holds key-value observations for an `AVPlayer` instance.
@MainActor
final class FKMediaPlayerKVO {

  private var observations: [NSKeyValueObservation] = []

  func observe(
    player: AVPlayer,
    onRateChange: @escaping () -> Void,
    onTimeControlStatusChange: @escaping () -> Void,
    onCurrentItemChange: @escaping () -> Void
  ) {
    invalidate()

    let rate = MainActorCallback(onRateChange)
    let timeControl = MainActorCallback(onTimeControlStatusChange)
    let currentItem = MainActorCallback(onCurrentItemChange)

    observations.append(
      player.observe(\.rate, options: [.new]) { _, _ in
        rate.schedule()
      }
    )

    observations.append(
      player.observe(\.timeControlStatus, options: [.new]) { _, _ in
        timeControl.schedule()
      }
    )

    observations.append(
      player.observe(\.currentItem, options: [.new]) { _, _ in
        currentItem.schedule()
      }
    )
  }

  func observe(
    item: AVPlayerItem,
    onStatusChange: @escaping () -> Void,
    onPlaybackLikelyToKeepUpChange: @escaping () -> Void,
    onPlaybackBufferEmptyChange: @escaping () -> Void,
    onLoadedTimeRangesChange: @escaping () -> Void
  ) {
    invalidate()

    let status = MainActorCallback(onStatusChange)
    let keepUp = MainActorCallback(onPlaybackLikelyToKeepUpChange)
    let bufferEmpty = MainActorCallback(onPlaybackBufferEmptyChange)
    let loadedRanges = MainActorCallback(onLoadedTimeRangesChange)

    observations.append(
      item.observe(\.status, options: [.new]) { _, _ in
        status.schedule()
      }
    )

    observations.append(
      item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { _, _ in
        keepUp.schedule()
      }
    )

    observations.append(
      item.observe(\.isPlaybackBufferEmpty, options: [.new]) { _, _ in
        bufferEmpty.schedule()
      }
    )

    observations.append(
      item.observe(\.loadedTimeRanges, options: [.new]) { _, _ in
        loadedRanges.schedule()
      }
    )
  }

  func invalidate() {
    observations.forEach { $0.invalidate() }
    observations.removeAll()
  }

}

/// Bridges non-Sendable UI callbacks into `@Sendable` KVO closures.
private final class MainActorCallback: @unchecked Sendable {
  private let handler: () -> Void

  init(_ handler: @escaping () -> Void) {
    self.handler = handler
  }

  func schedule() {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        self.handler()
      }
    } else {
      Task { @MainActor in
        self.handler()
      }
    }
  }
}
