import FKCoreKit
import UIKit

// MARK: - Source

/// Where the user picks media from.
public enum FKPhotoPickerSource: Sendable, Equatable {
  /// System photo library via `PHPickerViewController`.
  case photoLibrary
  /// Rear or default camera via `UIImagePickerController`.
  case camera
  /// Front-facing camera.
  case cameraFront
  /// Rear-facing camera.
  case cameraBack
  /// Presents a source chooser (photo library or camera).
  case libraryOrCamera
  /// Host-resolved source wrapped for custom chooser flows.
  indirect case custom(FKPhotoPickerSource)
}

// MARK: - Presentation

/// Modal presentation style for system pickers.
public enum FKPhotoPickerPresentation: Sendable, Equatable {
  /// Full screen for camera; page sheet for library on iPhone.
  case automatic
  /// Full-screen modal.
  case fullScreen
  /// Page sheet (typical library picker on iPhone).
  case pageSheet
  /// Popover (iPad); requires a popover anchor at presentation time.
  case popover
}

/// Popover anchor supplied when presenting from a host view controller.
@MainActor
public enum FKPhotoPickerPopoverAnchor: Equatable {
  /// Anchor to a view and optional source rect.
  case sourceView(UIView, sourceRect: CGRect? = nil)
  /// Anchor to a bar button item.
  case barButtonItem(UIBarButtonItem)
}

/// Presentation tuning for system pickers.
public struct FKPhotoPickerPresentationConfiguration: Sendable, Equatable {
  /// Preferred modal style.
  public var style: FKPhotoPickerPresentation

  public init(style: FKPhotoPickerPresentation = .automatic) {
    self.style = style
  }
}

// MARK: - Selection

/// Behavior when the user selects more items than the configured limit.
public enum FKPhotoPickerOverflowBehavior: Sendable, Equatable {
  /// Fail with ``FKPhotoPickerError/selectionLimitExceeded(selected:limit:)``.
  case fail
  /// Keep only the first `limit` items in selection order.
  case takeFirst(limit: Int)
}

/// Selection count and overflow handling.
public struct FKPhotoPickerSelectionPolicy: Sendable, Equatable {
  /// Maximum selectable items (`1` = single selection). Clamped to `1...50` internally.
  public var limit: Int
  /// What to do when selection exceeds `limit`.
  public var overflowBehavior: FKPhotoPickerOverflowBehavior

  public init(
    limit: Int = 1,
    overflowBehavior: FKPhotoPickerOverflowBehavior = .fail
  ) {
    self.limit = limit
    self.overflowBehavior = overflowBehavior
  }

  /// Clamped selection limit used by pickers.
  public var effectiveLimit: Int {
    min(max(limit, 1), 50)
  }

  /// Item count kept when ``FKPhotoPickerOverflowBehavior/takeFirst(limit:)`` trims an over-limit selection.
  public var overflowTrimLimit: Int {
    switch overflowBehavior {
    case .fail:
      return effectiveLimit
    case let .takeFirst(takeLimit):
      return min(max(takeLimit, 1), effectiveLimit)
    }
  }
}

// MARK: - Media types

/// Supported media categories for picking.
public struct FKPhotoPickerMediaTypes: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let images = FKPhotoPickerMediaTypes(rawValue: 1 << 0)
  public static let videos = FKPhotoPickerMediaTypes(rawValue: 1 << 1)
  public static let livePhotos = FKPhotoPickerMediaTypes(rawValue: 1 << 2)

  public static let imagesAndVideos: FKPhotoPickerMediaTypes = [.images, .videos]
}

/// Resolved media kind for a picked asset.
public enum FKPhotoPickerMediaType: Sendable, Equatable {
  case image
  case video
  case livePhoto
}

// MARK: - Delivery

/// Which representations to include in ``FKPhotoPickerResult``.
public enum FKPhotoPickerDelivery: Sendable, Equatable {
  case image
  case compressedData
  case fileURL
  case imageAndFileURL
  case imageAndData
}

// MARK: - Live Photo

/// How Live Photos are exported when included in ``FKPhotoPickerMediaTypes/livePhotos``.
public enum FKLivePhotoExportPolicy: Sendable, Equatable {
  /// Export a still image only.
  case stillImageOnly
  /// Export still image and paired MOV file URL.
  ///
  /// Currently exports the still image only; paired MOV export is reserved for a future release.
  case pairedMovieAndStill
  /// Skip Live Photos during multi-select.
  case skip
}

// MARK: - Permission

/// Permission preflight behavior before presenting system pickers.
public struct FKPhotoPickerPermissionPolicy: Sendable, Equatable {
  /// When `true`, requests `.photoLibraryRead` before library presentation (legacy fallback).
  public var checksPhotoLibrary: Bool
  /// When `true`, requests `.camera` before camera presentation.
  public var checksCamera: Bool
  /// Optional pre-prompt shown before the photo library system dialog.
  public var photoLibraryPrePrompt: FKPermissionPrePrompt?
  /// Optional pre-prompt shown before the camera system dialog.
  public var cameraPrePrompt: FKPermissionPrePrompt?
  /// When `true`, opens Settings after a denied permission (usually handled by the host).
  public var opensSettingsOnDenied: Bool

  public init(
    checksPhotoLibrary: Bool = false,
    checksCamera: Bool = true,
    photoLibraryPrePrompt: FKPermissionPrePrompt? = nil,
    cameraPrePrompt: FKPermissionPrePrompt? = nil,
    opensSettingsOnDenied: Bool = false
  ) {
    self.checksPhotoLibrary = checksPhotoLibrary
    self.checksCamera = checksCamera
    self.photoLibraryPrePrompt = photoLibraryPrePrompt
    self.cameraPrePrompt = cameraPrePrompt
    self.opensSettingsOnDenied = opensSettingsOnDenied
  }
}

// MARK: - Camera & video

/// Camera-specific options mapped to `UIImagePickerController`.
public struct FKPhotoPickerCameraOptions: Sendable, Equatable {
  public var allowsEditing: Bool
  public var cameraDevice: UIImagePickerController.CameraDevice?
  public var flashMode: UIImagePickerController.CameraFlashMode?
  public var showsCameraControls: Bool

  public init(
    allowsEditing: Bool = false,
    cameraDevice: UIImagePickerController.CameraDevice? = nil,
    flashMode: UIImagePickerController.CameraFlashMode? = nil,
    showsCameraControls: Bool = true
  ) {
    self.allowsEditing = allowsEditing
    self.cameraDevice = cameraDevice
    self.flashMode = flashMode
    self.showsCameraControls = showsCameraControls
  }
}

/// Video capture and export limits.
public struct FKPhotoPickerVideoOptions: Sendable, Equatable {
  /// Maximum recording duration for camera capture (`0` = system default).
  public var maximumDuration: TimeInterval
  /// Optional maximum file size in bytes after copy; fails with `.fileTooLarge` when exceeded.
  public var maxVideoBytes: Int?

  public init(maximumDuration: TimeInterval = 0, maxVideoBytes: Int? = nil) {
    self.maximumDuration = maximumDuration
    self.maxVideoBytes = maxVideoBytes
  }
}

// MARK: - Temp files

/// Lifecycle policy for exported temporary files.
public enum FKPhotoPickerTempFilePolicy: Sendable, Equatable {
  /// Host deletes files when no longer needed (default).
  case hostResponsible
  /// Coordinator deletes tracked URLs on deinitialization.
  case deleteOnDeinit
  /// Coordinator deletes tracked URLs after a delay following completion.
  case deleteAfterCompletion(seconds: TimeInterval)
}

// MARK: - Root configuration

/// Complete pick-session configuration for ``FKPhotoPicker``.
public struct FKPhotoPickerConfiguration: Sendable, Equatable {
  public var source: FKPhotoPickerSource
  public var mediaTypes: FKPhotoPickerMediaTypes
  public var selection: FKPhotoPickerSelectionPolicy
  public var delivery: FKPhotoPickerDelivery
  public var compression: FKPhotoCompressionOptions
  public var permission: FKPhotoPickerPermissionPolicy
  public var presentation: FKPhotoPickerPresentationConfiguration
  public var camera: FKPhotoPickerCameraOptions
  public var video: FKPhotoPickerVideoOptions
  public var livePhoto: FKLivePhotoExportPolicy
  public var tempFilePolicy: FKPhotoPickerTempFilePolicy
  /// When `true`, an empty picker confirmation returns `[]` instead of `.cancelled`.
  public var allowsEmptySelection: Bool
  /// Asset representation preference for PHPicker (`current` vs `compatible`).
  public var prefersCompatibleRepresentation: Bool

  public init(
    source: FKPhotoPickerSource = .photoLibrary,
    mediaTypes: FKPhotoPickerMediaTypes = .images,
    selection: FKPhotoPickerSelectionPolicy = .init(),
    delivery: FKPhotoPickerDelivery = .imageAndFileURL,
    compression: FKPhotoCompressionOptions = .init(),
    permission: FKPhotoPickerPermissionPolicy = .init(),
    presentation: FKPhotoPickerPresentationConfiguration = .init(),
    camera: FKPhotoPickerCameraOptions = .init(),
    video: FKPhotoPickerVideoOptions = .init(),
    livePhoto: FKLivePhotoExportPolicy = .stillImageOnly,
    tempFilePolicy: FKPhotoPickerTempFilePolicy = .hostResponsible,
    allowsEmptySelection: Bool = false,
    prefersCompatibleRepresentation: Bool = true
  ) {
    self.source = source
    self.mediaTypes = mediaTypes
    self.selection = selection
    self.delivery = delivery
    self.compression = compression
    self.permission = permission
    self.presentation = presentation
    self.camera = camera
    self.video = video
    self.livePhoto = livePhoto
    self.tempFilePolicy = tempFilePolicy
    self.allowsEmptySelection = allowsEmptySelection
    self.prefersCompatibleRepresentation = prefersCompatibleRepresentation
  }
}

/// Progress callback for multi-asset processing (`processed`, `total`), invoked on the main actor.
public typealias FKPhotoPickerProgressHandler = @MainActor @Sendable (Int, Int) -> Void
