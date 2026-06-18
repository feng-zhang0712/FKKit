extension FKVideoPlayerConfiguration {
  /// Slim embedded preset for gallery video pages: no PiP, AirPlay, or settings chrome.
  public static func galleryEmbedded() -> FKVideoPlayerConfiguration {
    var configuration = FKVideoPlayerConfiguration.default
    configuration.media.enablesNowPlayingInfo = false
    configuration.media.enablesRemoteCommands = false
    configuration.ui.allowsPictureInPicture = false
    configuration.ui.allowsAirPlay = false
    configuration.ui.controlsAutoHideInterval = 4.0
    configuration.ui.showsRemainingTime = false
    configuration.ui.gestureSeekSeconds = 0
    configuration.ui.allowsSurfacePanGestures = false
    configuration.ui.allowsDoubleTapSeek = false
    configuration.ui.allowsTapToToggleControls = false
    return configuration
  }
}
