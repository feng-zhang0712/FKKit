import UIKit

/// Dependency-injection surface for photo and video picking.
@MainActor
public protocol FKPhotoPicking: AnyObject {
  /// Presents a system picker and returns processed results.
  func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration
  ) async throws -> [FKPhotoPickerResult]
}

/// Coordinates system photo library and camera pickers with permission preflight and post-processing.
@MainActor
public final class FKPhotoPicker: FKPhotoPicking {
  private let coordinator = FKPhotoPickerCoordinator()

  public init() {}

  /// Presents a picker (``FKPhotoPicking`` requirement).
  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration
  ) async throws -> [FKPhotoPickerResult] {
    try await pick(
      from: viewController,
      configuration: configuration,
      popoverAnchor: nil,
      progressHandler: nil
    )
  }

  /// Presents a picker with optional popover anchor and multi-asset progress reporting.
  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration = FKPhotoPickerDefaults.configuration,
    popoverAnchor: FKPhotoPickerPopoverAnchor?,
    progressHandler: FKPhotoPickerProgressHandler?
  ) async throws -> [FKPhotoPickerResult] {
    try await coordinator.pick(
      from: viewController,
      configuration: configuration,
      popoverAnchor: popoverAnchor,
      progressHandler: progressHandler
    )
  }

  /// Closure-based pick API.
  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration = FKPhotoPickerDefaults.configuration,
    popoverAnchor: FKPhotoPickerPopoverAnchor? = nil,
    progressHandler: FKPhotoPickerProgressHandler? = nil,
    completion: @escaping @Sendable (Result<[FKPhotoPickerResult], FKPhotoPickerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        let results = try await pick(
          from: viewController,
          configuration: configuration,
          popoverAnchor: popoverAnchor,
          progressHandler: progressHandler
        )
        completion(.success(results))
      } catch let error as FKPhotoPickerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.processingFailed(underlyingDescription: error.localizedDescription)))
      }
    }
  }

  /// Presents the limited photo library management UI when access is `.limited`.
  public func presentLimitedLibraryManagement(from viewController: UIViewController) {
    coordinator.presentLimitedLibraryManagement(from: viewController)
  }
}
