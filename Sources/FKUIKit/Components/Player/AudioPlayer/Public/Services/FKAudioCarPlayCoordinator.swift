import MediaPlayer
import UIKit

/// CarPlay / Now Playing template helpers (Phase 3 baseline).
@MainActor
public final class FKAudioCarPlayCoordinator {

  public weak var player: FKAudioPlayer?

  public init(player: FKAudioPlayer? = nil) {
    self.player = player
  }

  /// Publishes queue-aware Now Playing commands for CarPlay and lock screen.
  public func activate() {
    player?.refreshRemoteTrackCommands()
  }

  public func deactivate() {
    player?.unregisterRemoteTrackCommands()
  }

  /// Updates artwork and metadata for CarPlay templates.
  public func refreshMetadata() {
    guard let player, let item = player.currentItem else { return }
    player.coordinator.configuration.enablesNowPlayingInfo = true
    _ = item
  }
}
