import UIKit

extension FKMediaGalleryItem {
  /// Maps a single photo picker result into a gallery item when possible.
  public static func from(_ result: FKPhotoPickerResult) -> FKMediaGalleryItem? {
    let id = result.id
    switch result.mediaType {
    case .image:
      if let image = result.image {
        return FKMediaGalleryItem(id: id, kind: .image(.image(image)))
      }
      if let fileURL = result.fileURL {
        return FKMediaGalleryItem(id: id, kind: .image(.url(fileURL)))
      }
      return nil
    case .video:
      guard let fileURL = result.fileURL else { return nil }
      var item = FKVideoItem(
        id: id,
        source: .url(fileURL),
        posterURL: nil
      )
      if let thumbnail = result.thumbnail,
         let data = thumbnail.jpegData(compressionQuality: 0.85) {
        let posterURL = FileManager.default.temporaryDirectory
          .appendingPathComponent("\(id)-poster.jpg")
        if (try? data.write(to: posterURL, options: .atomic)) != nil {
          item.posterURL = posterURL
        }
      }
      return FKMediaGalleryItem(
        id: id,
        kind: .video(.item(item))
      )
    case .livePhoto:
      if let image = result.image {
        return FKMediaGalleryItem(id: id, kind: .image(.image(image)))
      }
      if let fileURL = result.fileURL {
        return FKMediaGalleryItem(id: id, kind: .image(.url(fileURL)))
      }
      return nil
    }
  }

  /// Maps photo picker results into gallery items, omitting unsupported entries.
  public static func from(_ results: [FKPhotoPickerResult]) -> [FKMediaGalleryItem] {
    results.compactMap(FKMediaGalleryItem.from)
  }
}
