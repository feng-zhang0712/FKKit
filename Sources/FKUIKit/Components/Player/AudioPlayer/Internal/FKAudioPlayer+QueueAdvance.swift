import Foundation

extension FKAudioPlayer {

  public func applyLoopModeFromQueue() {
    switch queue.mode {
    case .repeatOne:
      coordinator.configuration.playback.loopMode = .one
    case .repeatAll:
      coordinator.configuration.playback.loopMode = .all
    case .sequential, .shuffle:
      coordinator.configuration.playback.loopMode = .none
    }
    refreshRemoteTrackCommands()
    boundView?.refreshQueueModeChrome()
  }

  /// When the Core playlist drives repeat-all, skip commands are handled by ``FKMediaPlaybackCoordinator``.
  var usesCoordinatorPlaylistNavigation: Bool {
    queue.items.count > 1 && queue.mode == .repeatAll
  }

  func refreshRemoteTrackCommands() {
    if usesCoordinatorPlaylistNavigation {
      unregisterRemoteTrackCommands()
    } else {
      registerRemoteTrackCommands()
    }
  }

  func performTrackTransition(to item: FKAudioItem, autoPlay: Bool) async {
    let fade = configuration.playback.fadeBetweenTracksDuration
    guard let fade, fade > 0 else {
      loadTrack(item, autoPlay: autoPlay)
      return
    }

    let steps = 8
    let stepDuration = fade / Double(steps)
    let originalVolume = coordinator.volume
    for _ in 0..<steps {
      coordinator.volume = max(0, coordinator.volume - originalVolume / Float(steps))
      try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
    }
    loadTrack(item, autoPlay: false)
    if autoPlay {
      coordinator.play()
    }
    for step in 1...steps {
      coordinator.volume = originalVolume * Float(step) / Float(steps)
      try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
    }
    coordinator.volume = originalVolume
  }

}
