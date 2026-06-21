/// Factory presets for common gallery flows.
public enum FKMediaGalleryPresets {
  /// Social feed: hero transition, mixed media, numeric page indicator, Wi‑Fi autoplay.
  public static func socialFeed() -> FKMediaGalleryConfiguration {
    FKMediaGalleryConfiguration(
      presentationStyle: .overFullScreen,
      transition: .hero(.init()),
      progressiveLoading: FKMediaGalleryProgressiveLoadingConfiguration(),
      video: FKMediaGalleryVideoConfiguration(
        autoplayCurrentVideo: true,
        mutedByDefault: false,
        cellularAutoplayPolicy: .wifiOnly
      ),
      contextMenu: FKMediaGalleryContextMenuConfiguration(),
      chrome: FKMediaGalleryChromeConfiguration(
        pageIndicatorStyle: .numeric,
        showsShareButton: true
      )
    )
  }

  /// Chat attachments: cross-dissolve, muted by default, update-friendly chrome.
  public static func chatAttachments() -> FKMediaGalleryConfiguration {
    FKMediaGalleryConfiguration(
      presentationStyle: .fullScreen,
      transition: .crossDissolve,
      video: FKMediaGalleryVideoConfiguration(
        autoplayCurrentVideo: false,
        mutedByDefault: true,
        cellularAutoplayPolicy: .never
      ),
      chrome: FKMediaGalleryChromeConfiguration(
        showsShareButton: false,
        showsCaption: false
      )
    )
  }

  /// Product detail: high zoom, no autoplay, numeric indicator.
  public static func productDetail() -> FKMediaGalleryConfiguration {
    FKMediaGalleryConfiguration(
      transition: .crossDissolve,
      zoom: FKMediaGalleryZoomConfiguration(maximumZoomScale: 6.0, doubleTapZoomScale: 3.0),
      video: FKMediaGalleryVideoConfiguration(
        autoplayCurrentVideo: false,
        cellularAutoplayPolicy: .never
      ),
      chrome: FKMediaGalleryChromeConfiguration(showsShareButton: false)
    )
  }

  /// Preview-only: no share or edit actions.
  public static func previewOnly() -> FKMediaGalleryConfiguration {
    FKMediaGalleryConfiguration(
      transition: .crossDissolve,
      contextMenu: FKMediaGalleryContextMenuConfiguration(
        showsShareAction: false,
        showsEditAction: false
      ),
      chrome: FKMediaGalleryChromeConfiguration(
        showsShareButton: false,
        showsCaption: false
      )
    )
  }

  /// Authenticated CDN: conservative autoplay defaults.
  public static func authenticatedCDN() -> FKMediaGalleryConfiguration {
    FKMediaGalleryConfiguration(
      transition: .crossDissolve,
      video: FKMediaGalleryVideoConfiguration(
        autoplayCurrentVideo: false,
        cellularAutoplayPolicy: .never
      )
    )
  }
}

/// Global default configuration when callers omit an explicit value.
public enum FKMediaGalleryDefaults {
  public nonisolated(unsafe) static var configuration: FKMediaGalleryConfiguration = FKMediaGalleryPresets.socialFeed()
}
