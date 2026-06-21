import UIKit

public extension FKMediaGallery {
  /// Presents a gallery using the ``FKMediaGalleryDefaults/configuration`` preset.
  static func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    transitionSource: FKMediaGalleryTransitionSource? = nil,
    configuration: FKMediaGalleryConfiguration = FKMediaGalleryDefaults.configuration,
    delegate: FKMediaGalleryDelegate? = nil
  ) throws {
    let gallery = FKMediaGallery(configuration: configuration)
    gallery.delegate = delegate
    try gallery.present(
      from: viewController,
      items: items,
      startIndex: startIndex,
      transitionSource: transitionSource,
      configuration: configuration
    )
  }
}
