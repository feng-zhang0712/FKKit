import FKCoreKit
import Foundation

/// Typed failures for photo and video pick sessions.
public enum FKPhotoPickerError: Error, Sendable, Equatable {
  case cancelled
  case permissionDenied(FKPermissionKind)
  case permissionError(FKPermissionError)
  case cameraUnavailable
  case sourceUnavailable(FKPhotoPickerSource)
  case alreadyPresenting
  case selectionLimitExceeded(selected: Int, limit: Int)
  case processingFailed(underlyingDescription: String)
  case fileTooLarge(bytes: Int, max: Int)
  case unsupportedMediaType
  case emptySelection
  case underlying(code: Int, domain: String)
}

extension FKPhotoPickerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .cancelled:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.cancelled")
    case let .permissionDenied(kind):
      return FKUIKitI18n.format("fkuikit.photo_picker.error.permission_denied", kind.localizedName)
    case let .permissionError(error):
      return error.localizedDescription
    case .cameraUnavailable:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.camera_unavailable")
    case .sourceUnavailable:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.source_unavailable")
    case .alreadyPresenting:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.already_presenting")
    case let .selectionLimitExceeded(selected, limit):
      return FKUIKitI18n.format("fkuikit.photo_picker.error.selection_limit", selected, limit)
    case let .processingFailed(description):
      return FKUIKitI18n.format("fkuikit.photo_picker.error.processing_failed", description)
    case let .fileTooLarge(bytes, max):
      return FKUIKitI18n.format("fkuikit.photo_picker.error.file_too_large", bytes, max)
    case .unsupportedMediaType:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.unsupported_media")
    case .emptySelection:
      return FKUIKitI18n.string("fkuikit.photo_picker.error.empty_selection")
    case let .underlying(code, domain):
      return FKUIKitI18n.format("fkuikit.photo_picker.error.underlying", domain, code)
    }
  }
}

extension FKPermissionKind {
  fileprivate var localizedName: String {
    switch self {
    case .camera:
      return FKUIKitI18n.string("fkuikit.photo_picker.permission.camera")
    case .photoLibraryRead:
      return FKUIKitI18n.string("fkuikit.photo_picker.permission.photo_library")
    case .photoLibraryAddOnly:
      return FKUIKitI18n.string("fkuikit.photo_picker.permission.photo_library_add")
    case .microphone:
      return FKUIKitI18n.string("fkuikit.photo_picker.permission.microphone")
    default:
      return String(describing: self)
    }
  }
}
