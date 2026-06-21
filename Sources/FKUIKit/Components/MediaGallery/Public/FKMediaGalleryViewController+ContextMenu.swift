import UIKit

extension FKMediaGalleryViewController: UIContextMenuInteractionDelegate {
  func installContextMenuInteraction() {
    let interaction = UIContextMenuInteraction(delegate: self)
    collectionView.addInteraction(interaction)
  }

  public func contextMenuInteraction(
    _ interaction: UIContextMenuInteraction,
    configurationForMenuAtLocation location: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard configuration.contextMenu.isEnabled, let item = currentItem else { return nil }
    guard !FKMediaGalleryItemResolver.isLivePhoto(item) else { return nil }
    return UIContextMenuConfiguration(identifier: nil, previewProvider: { [weak self] in
      self?.makeContextMenuPreviewController()
    }, actionProvider: { [weak self] _ in
      self?.makeContextMenu() ?? UIMenu(children: [])
    })
  }

  func makeContextMenu() -> UIMenu? {
    guard let item = currentItem else { return nil }
    return FKMediaGalleryContextMenuBuilder.makeMenu(
      for: item,
      configuration: configuration.contextMenu,
      handlers: .init(
        onSave: { [weak self] in
          guard let self, let item = self.currentItem else { return }
          Task { await self.saveGalleryItemToPhotos(item, at: self.currentIndex) }
        },
        onShare: { [weak self] in self?.shareCurrentItem() },
        onEdit: { [weak self] in
          guard let self, let item = self.currentItem, let gallery = self.gallery else { return }
          _ = self.galleryDelegate?.mediaGallery(gallery, didRequestEdit: item, at: self.currentIndex)
        }
      )
    )
  }

  private func makeContextMenuPreviewController() -> UIViewController? {
    guard let snapshot = currentPageView?.makeInteractiveDismissSnapshot() else { return nil }
    let controller = UIViewController()
    controller.view.backgroundColor = .black
    controller.preferredContentSize = view.bounds.size
    snapshot.frame = CGRect(origin: .zero, size: controller.preferredContentSize)
    snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    controller.view.addSubview(snapshot)
    return controller
  }
}
