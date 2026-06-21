import FKCoreKit
import UIKit

/// Coordinates full-screen mixed media gallery presentation.
@MainActor
public final class FKMediaGallery: FKMediaGalleryPresenting {
  /// Session-wide configuration defaults.
  public var configuration: FKMediaGalleryConfiguration
  /// Receives lifecycle and action callbacks.
  public weak var delegate: FKMediaGalleryDelegate?
  /// Optional custom per-page overlay provider.
  public weak var chromeProvider: (any FKMediaGalleryChromeProviding)?
  /// Optional custom image loader; defaults to ``FKImageLoader/shared``.
  public var imageLoader: (any FKImageLoading)?

  private let coordinator = FKMediaGalleryCoordinator()

  /// Creates a gallery coordinator.
  public init(
    configuration: FKMediaGalleryConfiguration = FKMediaGalleryDefaults.configuration,
    imageLoader: (any FKImageLoading)? = nil
  ) {
    self.configuration = configuration
    self.imageLoader = imageLoader
  }

  /// Currently presented gallery view controller, if any.
  public var viewController: FKMediaGalleryViewController? {
    coordinator.viewController
  }

  /// Presents the gallery from a host view controller.
  public func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    transitionSource: FKMediaGalleryTransitionSource? = nil,
    configuration: FKMediaGalleryConfiguration? = nil
  ) throws {
    let resolvedConfiguration = configuration ?? self.configuration
    try present(
      from: viewController,
      items: items,
      startIndex: startIndex,
      transitionSource: transitionSource,
      configuration: resolvedConfiguration
    )
  }

  /// Presents the gallery (``FKMediaGalleryPresenting`` requirement).
  public func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int,
    transitionSource: FKMediaGalleryTransitionSource?,
    configuration: FKMediaGalleryConfiguration
  ) throws {
    try coordinator.present(
      gallery: self,
      from: viewController,
      items: items,
      startIndex: startIndex,
      transitionSource: transitionSource,
      configuration: configuration
    )
  }

  /// Dismisses the active gallery session.
  public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
    coordinator.dismiss(animated: animated, completion: completion)
  }
}
