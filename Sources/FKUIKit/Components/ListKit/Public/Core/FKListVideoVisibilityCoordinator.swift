import UIKit

/// Optional ListKit helper that forwards scroll events to ``FKVideoFeedPlaybackCoordinator``.
@MainActor
public final class FKListVideoVisibilityCoordinator: NSObject {
  public let playbackCoordinator: FKVideoFeedPlaybackCoordinator

  public init(pool: FKVideoPlayerPool = FKVideoPlayerPool()) {
    self.playbackCoordinator = FKVideoFeedPlaybackCoordinator(pool: pool)
    super.init()
  }

  /// Binds the playback coordinator to a list scroll view.
  public func bind(scrollView: UIScrollView) {
    playbackCoordinator.scrollView = scrollView
  }

  /// Registers a player view participating in auto-play visibility rules.
  public func register(_ playerView: FKVideoPlayerView) {
    playbackCoordinator.register(playerView)
  }

  /// Unregisters a player view (call from cell reuse).
  public func unregister(_ playerView: FKVideoPlayerView) {
    playbackCoordinator.unregister(playerView)
  }

  /// Forwards `UIScrollViewDelegate/scrollViewDidScroll` from a list view controller.
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    playbackCoordinator.scrollViewDidScroll(scrollView)
  }

  /// Re-evaluates visible players after layout or snapshot changes.
  public func refreshVisibility() {
    playbackCoordinator.refreshVisibility()
  }
}
