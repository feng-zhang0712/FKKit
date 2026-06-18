import UIKit

/// Full-screen presentation style for the gallery host.
public enum FKMediaGalleryPresentationStyle: Sendable, Equatable {
  case fullScreen
  /// Recommended for hero transitions; allows a transparent backdrop during animation.
  case overFullScreen
}

/// Entry and exit transition style.
public enum FKMediaGalleryTransition: Sendable, Equatable {
  case hero(FKMediaGalleryHeroTransitionOptions)
  case crossDissolve
  case system
}

/// Hero transition tuning options.
public struct FKMediaGalleryHeroTransitionOptions: Sendable, Equatable {
  public var duration: TimeInterval
  public var backgroundDimmingAlpha: CGFloat
  public var usesSpringAnimation: Bool
  public var fadeInFullResolutionDuringTransition: Bool

  public init(
    duration: TimeInterval = 0.35,
    backgroundDimmingAlpha: CGFloat = 0.95,
    usesSpringAnimation: Bool = true,
    fadeInFullResolutionDuringTransition: Bool = false
  ) {
    self.duration = duration
    self.backgroundDimmingAlpha = backgroundDimmingAlpha
    self.usesSpringAnimation = usesSpringAnimation
    self.fadeInFullResolutionDuringTransition = fadeInFullResolutionDuringTransition
  }
}

/// Pinch and double-tap zoom behavior for image pages.
public struct FKMediaGalleryZoomConfiguration: Sendable, Equatable {
  public var minimumZoomScale: CGFloat
  public var maximumZoomScale: CGFloat
  public var doubleTapZoomScale: CGFloat
  public var allowsDoubleTap: Bool
  /// When `true`, double-tap zooms toward the tap point.
  public var doubleTapZoomsToFocalPoint: Bool

  public init(
    minimumZoomScale: CGFloat = 1.0,
    maximumZoomScale: CGFloat = 4.0,
    doubleTapZoomScale: CGFloat = 2.5,
    allowsDoubleTap: Bool = true,
    doubleTapZoomsToFocalPoint: Bool = true
  ) {
    self.minimumZoomScale = minimumZoomScale
    self.maximumZoomScale = maximumZoomScale
    self.doubleTapZoomScale = doubleTapZoomScale
    self.allowsDoubleTap = allowsDoubleTap
    self.doubleTapZoomsToFocalPoint = doubleTapZoomsToFocalPoint
  }
}

/// Feed-to-fullscreen progressive image loading.
public struct FKMediaGalleryProgressiveLoadingConfiguration: Sendable, Equatable {
  public var enabled: Bool
  public var fullSizeCrossfadeDuration: TimeInterval
  public var showsProgressIndicator: Bool

  public init(
    enabled: Bool = true,
    fullSizeCrossfadeDuration: TimeInterval = 0.2,
    showsProgressIndicator: Bool = true
  ) {
    self.enabled = enabled
    self.fullSizeCrossfadeDuration = fullSizeCrossfadeDuration
    self.showsProgressIndicator = showsProgressIndicator
  }
}

/// Autoplay policy for gallery videos.
public enum FKMediaGalleryAutoplayPolicy: Sendable, Equatable {
  case always
  case wifiOnly
  case never
}

/// Video playback behavior inside the gallery.
public struct FKMediaGalleryVideoConfiguration: Sendable, Equatable {
  public var autoplayCurrentVideo: Bool
  public var loopsCurrentVideo: Bool
  public var mutedByDefault: Bool
  public var showsMuteButton: Bool
  public var pauseWhenScrolling: Bool
  public var teardownPlayerWhenOffscreen: Bool
  public var cellularAutoplayPolicy: FKMediaGalleryAutoplayPolicy
  public var allowsScrubbing: Bool
  public var playerConfiguration: FKVideoPlayerConfiguration

  public init(
    autoplayCurrentVideo: Bool = true,
    loopsCurrentVideo: Bool = false,
    mutedByDefault: Bool = false,
    showsMuteButton: Bool = true,
    pauseWhenScrolling: Bool = true,
    teardownPlayerWhenOffscreen: Bool = true,
    cellularAutoplayPolicy: FKMediaGalleryAutoplayPolicy = .wifiOnly,
    allowsScrubbing: Bool = true,
    playerConfiguration: FKVideoPlayerConfiguration = .galleryEmbedded()
  ) {
    self.autoplayCurrentVideo = autoplayCurrentVideo
    self.loopsCurrentVideo = loopsCurrentVideo
    self.mutedByDefault = mutedByDefault
    self.showsMuteButton = showsMuteButton
    self.pauseWhenScrolling = pauseWhenScrolling
    self.teardownPlayerWhenOffscreen = teardownPlayerWhenOffscreen
    self.cellularAutoplayPolicy = cellularAutoplayPolicy
    self.allowsScrubbing = allowsScrubbing
    self.playerConfiguration = playerConfiguration
  }
}

/// Audio session behavior while the gallery is visible.
public enum FKMediaGalleryAudioSessionPolicy: Sendable, Equatable {
  case ambient
  case soloAmbient
  case duckOthers
}

/// Interactive swipe-to-dismiss tuning.
public struct FKMediaGalleryDismissGestureConfiguration: Sendable, Equatable {
  public var allowsInteractiveDismiss: Bool
  public var dismissDistanceRatio: CGFloat
  public var dismissVelocityThreshold: CGFloat
  public var allowsDismissFromVideoPage: Bool

  public init(
    allowsInteractiveDismiss: Bool = true,
    dismissDistanceRatio: CGFloat = 0.22,
    dismissVelocityThreshold: CGFloat = 900,
    allowsDismissFromVideoPage: Bool = true
  ) {
    self.allowsInteractiveDismiss = allowsInteractiveDismiss
    self.dismissDistanceRatio = dismissDistanceRatio
    self.dismissVelocityThreshold = dismissVelocityThreshold
    self.allowsDismissFromVideoPage = allowsDismissFromVideoPage
  }
}

/// Single-tap behavior on page content.
public enum FKMediaGallerySingleTapBehavior: Sendable, Equatable {
  case toggleChrome
  case toggleChromeAndVideoControls
  case none
}

/// Tap and double-tap interaction policy.
public struct FKMediaGalleryInteractionConfiguration: Sendable, Equatable {
  public var singleTapBehavior: FKMediaGallerySingleTapBehavior
  public var videoDoubleTapTogglesPlayback: Bool

  public init(
    singleTapBehavior: FKMediaGallerySingleTapBehavior = .toggleChrome,
    videoDoubleTapTogglesPlayback: Bool = true
  ) {
    self.singleTapBehavior = singleTapBehavior
    self.videoDoubleTapTogglesPlayback = videoDoubleTapTogglesPlayback
  }
}

/// Long-press context menu options.
public struct FKMediaGalleryContextMenuConfiguration: Sendable, Equatable {
  public var isEnabled: Bool
  public var showsSaveToPhotosAction: Bool
  public var showsShareAction: Bool
  public var showsCopyLinkAction: Bool
  public var showsEditAction: Bool

  public init(
    isEnabled: Bool = true,
    showsSaveToPhotosAction: Bool = true,
    showsShareAction: Bool = true,
    showsCopyLinkAction: Bool = true,
    showsEditAction: Bool = false
  ) {
    self.isEnabled = isEnabled
    self.showsSaveToPhotosAction = showsSaveToPhotosAction
    self.showsShareAction = showsShareAction
    self.showsCopyLinkAction = showsCopyLinkAction
    self.showsEditAction = showsEditAction
  }
}

/// Page indicator style for chrome.
public enum FKMediaGalleryPageIndicatorStyle: Sendable, Equatable {
  case numeric
  case dots
  case none
}

/// Background treatment for the gallery host.
public enum FKMediaGalleryBackgroundStyle: Sendable, Equatable {
  case black
  case blackTranslucent
  case blur(UIBlurEffect.Style)
}

/// Top chrome configuration.
public struct FKMediaGalleryChromeConfiguration: Sendable, Equatable {
  public var showsCloseButton: Bool
  public var showsPageIndicator: Bool
  public var pageIndicatorStyle: FKMediaGalleryPageIndicatorStyle
  public var showsMuteButton: Bool
  public var showsShareButton: Bool
  public var showsCaption: Bool
  public var chromeAutoHideInterval: TimeInterval?
  public var backgroundStyle: FKMediaGalleryBackgroundStyle
  public var statusBarStyle: UIStatusBarStyle?

  public init(
    showsCloseButton: Bool = true,
    showsPageIndicator: Bool = true,
    pageIndicatorStyle: FKMediaGalleryPageIndicatorStyle = .numeric,
    showsMuteButton: Bool = true,
    showsShareButton: Bool = false,
    showsCaption: Bool = true,
    chromeAutoHideInterval: TimeInterval? = nil,
    backgroundStyle: FKMediaGalleryBackgroundStyle = .black,
    statusBarStyle: UIStatusBarStyle? = nil
  ) {
    self.showsCloseButton = showsCloseButton
    self.showsPageIndicator = showsPageIndicator
    self.pageIndicatorStyle = pageIndicatorStyle
    self.showsMuteButton = showsMuteButton
    self.showsShareButton = showsShareButton
    self.showsCaption = showsCaption
    self.chromeAutoHideInterval = chromeAutoHideInterval
    self.backgroundStyle = backgroundStyle
    self.statusBarStyle = statusBarStyle
  }
}

/// Root sendable configuration for a gallery session.
public struct FKMediaGalleryConfiguration: Sendable, Equatable {
  public var presentationStyle: FKMediaGalleryPresentationStyle
  public var transition: FKMediaGalleryTransition
  public var zoom: FKMediaGalleryZoomConfiguration
  public var progressiveLoading: FKMediaGalleryProgressiveLoadingConfiguration
  public var video: FKMediaGalleryVideoConfiguration
  public var audioSession: FKMediaGalleryAudioSessionPolicy
  public var dismissGesture: FKMediaGalleryDismissGestureConfiguration
  public var interaction: FKMediaGalleryInteractionConfiguration
  public var contextMenu: FKMediaGalleryContextMenuConfiguration
  public var chrome: FKMediaGalleryChromeConfiguration
  public var prefetchNeighborCount: Int
  public var dismissWhenItemsBecomeEmpty: Bool
  public var statusBarHidden: Bool
  public var supportedInterfaceOrientations: UIInterfaceOrientationMask

  public init(
    presentationStyle: FKMediaGalleryPresentationStyle = .overFullScreen,
    transition: FKMediaGalleryTransition = .hero(.init()),
    zoom: FKMediaGalleryZoomConfiguration = .init(),
    progressiveLoading: FKMediaGalleryProgressiveLoadingConfiguration = .init(),
    video: FKMediaGalleryVideoConfiguration = .init(),
    audioSession: FKMediaGalleryAudioSessionPolicy = .ambient,
    dismissGesture: FKMediaGalleryDismissGestureConfiguration = .init(),
    interaction: FKMediaGalleryInteractionConfiguration = .init(),
    contextMenu: FKMediaGalleryContextMenuConfiguration = .init(),
    chrome: FKMediaGalleryChromeConfiguration = .init(),
    prefetchNeighborCount: Int = 1,
    dismissWhenItemsBecomeEmpty: Bool = true,
    statusBarHidden: Bool = true,
    supportedInterfaceOrientations: UIInterfaceOrientationMask = .allButUpsideDown
  ) {
    self.presentationStyle = presentationStyle
    self.transition = transition
    self.zoom = zoom
    self.progressiveLoading = progressiveLoading
    self.video = video
    self.audioSession = audioSession
    self.dismissGesture = dismissGesture
    self.interaction = interaction
    self.contextMenu = contextMenu
    self.chrome = chrome
    self.prefetchNeighborCount = prefetchNeighborCount
    self.dismissWhenItemsBecomeEmpty = dismissWhenItemsBecomeEmpty
    self.statusBarHidden = statusBarHidden
    self.supportedInterfaceOrientations = supportedInterfaceOrientations
  }
}
