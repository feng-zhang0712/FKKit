import UIKit

public extension FKPhotoPicker {
  /// Picks a single avatar image using ``FKPhotoPickerPresets/avatar()``.
  static func pickAvatar(from viewController: UIViewController) async throws -> FKPhotoPickerResult {
    let picker = FKPhotoPicker()
    let results = try await picker.pick(from: viewController, configuration: .avatar())
    guard let first = results.first else { throw FKPhotoPickerError.emptySelection }
    return first
  }

  /// Picks up to `limit` compressed images using ``FKPhotoPickerPresets/chatAttachments(max:)``.
  static func pickImages(from viewController: UIViewController, limit: Int) async throws -> [FKPhotoPickerResult] {
    let picker = FKPhotoPicker()
    return try await picker.pick(
      from: viewController,
      configuration: .chatAttachments(max: limit)
    )
  }
}

public extension FKPhotoPickerConfiguration {
  /// Shorthand for ``FKPhotoPickerPresets/avatar()``.
  static func avatar() -> FKPhotoPickerConfiguration { FKPhotoPickerPresets.avatar() }

  /// Shorthand for ``FKPhotoPickerPresets/chatAttachments(max:)``.
  static func chatAttachments(max: Int = 9) -> FKPhotoPickerConfiguration {
    FKPhotoPickerPresets.chatAttachments(max: max)
  }

  /// Shorthand for ``FKPhotoPickerPresets/documentScan()``.
  static func documentScan() -> FKPhotoPickerConfiguration { FKPhotoPickerPresets.documentScan() }

  /// Shorthand for ``FKPhotoPickerPresets/highQualitySingle()``.
  static func highQualitySingle() -> FKPhotoPickerConfiguration { FKPhotoPickerPresets.highQualitySingle() }
}
