import FKCoreKit
import UIKit

/// Placeholder content shown before and during loading.
public enum FKImageViewPlaceholder: @unchecked Sendable {
  /// No dedicated placeholder layer.
  case none
  /// Static bitmap placeholder.
  case image(UIImage)
  /// Solid color fill.
  case color(UIColor)
  /// SF Symbol by name.
  case symbol(name: String, pointSize: CGFloat?, weight: UIImage.SymbolWeight?)
  /// Avatar-style initials on a colored background.
  case initials(
    text: String,
    font: UIFont?,
    textColor: UIColor?,
    backgroundColor: UIColor?
  )
}

/// Target pixel buffer policy for downsampling requests.
public enum FKImageViewTargetSizePolicy: Equatable, Sendable {
  /// Derive from laid-out bounds × screen scale after layout.
  case automaticFromBounds
  /// Host-provided point size (multiplied by screen scale when building the request).
  case explicit(CGSize)
  /// Full resolution (no target dimensions on the request).
  case none
}

/// Progress chrome while loading.
public enum FKImageViewProgressMode: @unchecked Sendable {
  /// No progress UI.
  case none
  /// Centered `UIActivityIndicatorView`.
  case activityIndicator
  /// Thin determinate/indeterminate bar pinned to the bottom edge.
  case linearProgress(FKProgressBarConfiguration?)
}

/// Loading overlay options (progress + optional skeleton).
public struct FKImageViewLoadingPresentation: @unchecked Sendable {
  /// Progress indicator mode.
  public var progressMode: FKImageViewProgressMode
  /// When `true`, shows a skeleton overlay via ``UIView/fk_showSkeleton(configuration:animated:respectsSafeArea:blocksInteraction:)``.
  public var includesSkeleton: Bool
  /// Optional skeleton override; `nil` uses ``FKSkeleton/defaultConfiguration``.
  public var skeletonConfiguration: FKSkeletonConfiguration?

  /// Creates loading presentation defaults.
  public init(
    progressMode: FKImageViewProgressMode = .none,
    includesSkeleton: Bool = false,
    skeletonConfiguration: FKSkeletonConfiguration? = nil
  ) {
    self.progressMode = progressMode
    self.includesSkeleton = includesSkeleton
    self.skeletonConfiguration = skeletonConfiguration
  }
}

/// Load behavior and placeholder configuration.
public struct FKImageViewLoadingConfiguration: @unchecked Sendable {
  /// Default placeholder when none is passed to ``FKImageView/load(url:placeholder:)``.
  public var placeholder: FKImageViewPlaceholder
  /// How target dimensions are resolved for ``FKImageLoadRequest``.
  public var targetSizePolicy: FKImageViewTargetSizePolicy
  /// When `true`, assigning ``FKImageView/url`` starts a load automatically.
  public var loadsAutomatically: Bool
  /// Progress and skeleton presentation while loading.
  public var loadingPresentation: FKImageViewLoadingPresentation
  /// Per-view cache policy override forwarded to ``FKImageLoader/loadImage(for:options:)``.
  public var cachePolicy: FKImageLoadCachePolicy
  /// Fractional bounds delta (0…1) that triggers a reload under ``FKImageViewTargetSizePolicy/automaticFromBounds``.
  public var boundsChangeReloadThreshold: CGFloat
  /// When `true`, synchronously reads memory cache before starting async load.
  public var checksMemoryCachePreview: Bool
  /// Optional pause when the view leaves the window hierarchy.
  public var pausesLoadingWhenOffscreen: Bool
  /// Optional factory for a custom placeholder view; takes precedence over ``placeholder``.
  public var customPlaceholderProvider: (@MainActor () -> UIView)?
  /// When `true`, successful loads skip disk persistence (memory cache still applies).
  public var excludesFromDiskCache: Bool
  /// When `true`, shows configured placeholder while ``FKImageViewState/idle``.
  public var showsPlaceholderWhenIdle: Bool

  /// Creates loading defaults.
  public init(
    placeholder: FKImageViewPlaceholder = .none,
    targetSizePolicy: FKImageViewTargetSizePolicy = .automaticFromBounds,
    loadsAutomatically: Bool = true,
    loadingPresentation: FKImageViewLoadingPresentation = .init(),
    cachePolicy: FKImageLoadCachePolicy = .default,
    boundsChangeReloadThreshold: CGFloat = 0.1,
    checksMemoryCachePreview: Bool = true,
    pausesLoadingWhenOffscreen: Bool = false,
    customPlaceholderProvider: (@MainActor () -> UIView)? = nil,
    excludesFromDiskCache: Bool = false,
    showsPlaceholderWhenIdle: Bool = false
  ) {
    self.placeholder = placeholder
    self.targetSizePolicy = targetSizePolicy
    self.loadsAutomatically = loadsAutomatically
    self.loadingPresentation = loadingPresentation
    self.cachePolicy = cachePolicy
    self.boundsChangeReloadThreshold = boundsChangeReloadThreshold
    self.checksMemoryCachePreview = checksMemoryCachePreview
    self.pausesLoadingWhenOffscreen = pausesLoadingWhenOffscreen
    self.customPlaceholderProvider = customPlaceholderProvider
    self.excludesFromDiskCache = excludesFromDiskCache
    self.showsPlaceholderWhenIdle = showsPlaceholderWhenIdle
  }
}
