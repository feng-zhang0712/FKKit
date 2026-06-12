import FKCoreKit
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class FKPhotoPickerCoordinator {
  enum SessionState {
    case idle
    case presenting
    case processing
  }

  private var state: SessionState = .idle
  private var retainSelf: FKPhotoPickerCoordinator?

  private var configuration = FKPhotoPickerDefaults.configuration
  private var popoverAnchor: FKPhotoPickerPopoverAnchor?
  private var progressHandler: FKPhotoPickerProgressHandler?
  private var tempStore = FKPhotoTempFileStore(policy: .hostResponsible)

  private var phpickerAdapter: FKPHPickerDelegateAdapter?
  private var imagePickerAdapter: FKImagePickerDelegateAdapter?
  private var pendingPHPickerResults: [PHPickerResult] = []
  private var pendingImagePickerInfo: [UIImagePickerController.InfoKey: Any]?
  private var sessionGate: FKPhotoPickerSessionGate?
  private var sourceChooserDismissObserver: FKPhotoPickerDismissObserver?

  func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration,
    popoverAnchor: FKPhotoPickerPopoverAnchor?,
    progressHandler: FKPhotoPickerProgressHandler?
  ) async throws -> [FKPhotoPickerResult] {
    guard state == .idle else {
      throw FKPhotoPickerError.alreadyPresenting
    }

    self.configuration = configuration
    self.popoverAnchor = popoverAnchor
    self.progressHandler = progressHandler
    self.tempStore = FKPhotoTempFileStore(policy: configuration.tempFilePolicy)
    self.retainSelf = self
    state = .presenting

    do {
      let resolvedSource = try await resolveSource(from: viewController, source: configuration.source)
      let results = try await runPickFlow(from: viewController, source: resolvedSource)
      tempStore.scheduleCleanupIfNeeded()
      finishSession()
      return results
    } catch {
      tempStore.scheduleCleanupIfNeeded()
      finishSession()
      throw error
    }
  }

  func presentLimitedLibraryManagement(from viewController: UIViewController) {
    PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
  }

  // MARK: - Flow

  private func resolveSource(
    from viewController: UIViewController,
    source: FKPhotoPickerSource
  ) async throws -> FKPhotoPickerSource {
    switch source {
    case .custom(let inner):
      return try await resolveSource(from: viewController, source: inner)
    case .libraryOrCamera:
      return try await presentSourceChooser(from: viewController)
    default:
      return source
    }
  }

  private func runPickFlow(
    from viewController: UIViewController,
    source: FKPhotoPickerSource
  ) async throws -> [FKPhotoPickerResult] {
    switch source {
    case .photoLibrary:
      try await checkPhotoLibraryPermissionIfNeeded()
      return try await presentPhotoLibrary(from: viewController)
    case .camera, .cameraFront, .cameraBack:
      try await checkCameraPermissionIfNeeded()
      return try await presentCamera(from: viewController, source: source)
    case .libraryOrCamera, .custom:
      throw FKPhotoPickerError.sourceUnavailable(source)
    }
  }

  // MARK: - Permissions

  private func checkPhotoLibraryPermissionIfNeeded() async throws {
    guard configuration.permission.checksPhotoLibrary else { return }
    let result = await FKPermissions.shared.request(
      .photoLibraryRead,
      prePrompt: configuration.permission.photoLibraryPrePrompt
    )
    if let error = result.error {
      throw FKPhotoPickerError.permissionError(error)
    }
    guard result.isGranted else {
      if configuration.permission.opensSettingsOnDenied {
        FKPermissions.shared.openAppSettings()
      }
      throw FKPhotoPickerError.permissionDenied(.photoLibraryRead)
    }
  }

  private func checkCameraPermissionIfNeeded() async throws {
    if configuration.permission.checksCamera {
      let result = await FKPermissions.shared.request(
        .camera,
        prePrompt: configuration.permission.cameraPrePrompt
      )
      if let error = result.error {
        throw FKPhotoPickerError.permissionError(error)
      }
      guard result.isGranted else {
        if configuration.permission.opensSettingsOnDenied {
          FKPermissions.shared.openAppSettings()
        }
        throw FKPhotoPickerError.permissionDenied(.camera)
      }
    }

    guard configuration.mediaTypes.contains(.videos) else { return }

    let microphoneResult = await FKPermissions.shared.request(.microphone)
    if let error = microphoneResult.error {
      throw FKPhotoPickerError.permissionError(error)
    }

    let requiresMicrophone = configuration.mediaTypes.contains(.videos)
      && !configuration.mediaTypes.contains(.images)
    guard requiresMicrophone, !microphoneResult.isGranted else { return }

    if configuration.permission.opensSettingsOnDenied {
      FKPermissions.shared.openAppSettings()
    }
    throw FKPhotoPickerError.permissionDenied(.microphone)
  }

  // MARK: - Source chooser

  private func presentSourceChooser(from viewController: UIViewController) async throws -> FKPhotoPickerSource {
    try await withCheckedThrowingContinuation { continuation in
      var hasResumed = false
      let resumeOnce: (Result<FKPhotoPickerSource, Error>) -> Void = { [weak self] result in
        guard !hasResumed else { return }
        hasResumed = true
        self?.sourceChooserDismissObserver = nil
        switch result {
        case let .success(source):
          continuation.resume(returning: source)
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }

      let libraryAction = FKActionSheetAction(
        title: FKUIKitI18n.string("fkuikit.photo_picker.source.library"),
        accessibilityLabel: FKUIKitI18n.string("fkuikit.photo_picker.source.library_a11y")
      ) { _ in
        resumeOnce(.success(.photoLibrary))
      }

      let cameraAction = FKActionSheetAction(
        title: FKUIKitI18n.string("fkuikit.photo_picker.source.camera"),
        accessibilityLabel: FKUIKitI18n.string("fkuikit.photo_picker.source.camera_a11y")
      ) { _ in
        resumeOnce(.success(.camera))
      }

      let cancelAction = FKActionSheetAction(
        title: FKUIKitI18n.string("fkuikit.common.cancel"),
        style: .cancel
      ) { _ in
        resumeOnce(.failure(FKPhotoPickerError.cancelled))
      }

      var sheetConfig = FKActionSheetConfiguration(
        sections: [FKActionSheetSection(actions: [libraryAction, cameraAction])],
        cancelAction: cancelAction
      )
      sheetConfig.hooks = FKActionSheetLifecycleHooks(
        didDismiss: { reason in
          if reason == .tapOutside || reason == .programmatic {
            resumeOnce(.failure(FKPhotoPickerError.cancelled))
          }
        }
      )

      do {
        let sheet = try FKActionSheet(configuration: sheetConfig)
        if let popoverAnchor {
          try presentActionSheet(sheet, from: viewController, anchor: popoverAnchor)
        } else {
          try sheet.present(from: viewController)
        }
      } catch {
        presentLegacySourceChooser(
          from: viewController,
          popoverAnchor: popoverAnchor,
          onLibrary: { resumeOnce(.success(.photoLibrary)) },
          onCamera: { resumeOnce(.success(.camera)) },
          onCancel: { resumeOnce(.failure(FKPhotoPickerError.cancelled)) }
        )
      }
    }
  }

  private func presentActionSheet(
    _ sheet: FKActionSheet,
    from viewController: UIViewController,
    anchor: FKPhotoPickerPopoverAnchor
  ) throws {
    switch anchor {
    case let .sourceView(sourceView, sourceRect):
      try sheet.present(from: viewController, anchoredTo: sourceView, sourceRect: sourceRect)
    case let .barButtonItem(item):
      try sheet.present(from: viewController, anchoredTo: item)
    }
  }

  private func presentLegacySourceChooser(
    from viewController: UIViewController,
    popoverAnchor: FKPhotoPickerPopoverAnchor?,
    onLibrary: @escaping () -> Void,
    onCamera: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(
      title: FKUIKitI18n.string("fkuikit.photo_picker.source.library"),
      style: .default
    ) { _ in onLibrary() })
    alert.addAction(UIAlertAction(
      title: FKUIKitI18n.string("fkuikit.photo_picker.source.camera"),
      style: .default
    ) { _ in onCamera() })
    alert.addAction(UIAlertAction(
      title: FKUIKitI18n.string("fkuikit.common.cancel"),
      style: .cancel
    ) { _ in onCancel() })

    if let popover = alert.popoverPresentationController, let popoverAnchor {
      switch popoverAnchor {
      case let .sourceView(sourceView, sourceRect):
        popover.sourceView = sourceView
        popover.sourceRect = sourceRect ?? sourceView.bounds
      case let .barButtonItem(item):
        popover.barButtonItem = item
      }
    }

    let observer = FKPhotoPickerDismissObserver {
      onCancel()
    }
    sourceChooserDismissObserver = observer
    alert.presentationController?.delegate = observer

    viewController.present(alert, animated: true)
  }

  // MARK: - PHPicker

  private func presentPhotoLibrary(from viewController: UIViewController) async throws -> [FKPhotoPickerResult] {
    let gate = FKPhotoPickerSessionGate()
    sessionGate = gate

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      var phpConfig = PHPickerConfiguration(photoLibrary: .shared())
      phpConfig.selectionLimit = configuration.selection.effectiveLimit
      phpConfig.filter = phpFilter(for: configuration.mediaTypes)
      phpConfig.preferredAssetRepresentationMode = configuration.prefersCompatibleRepresentation ? .compatible : .current

      let picker = PHPickerViewController(configuration: phpConfig)
      let adapter = FKPHPickerDelegateAdapter { [weak self] results in
        self?.pendingPHPickerResults = results
        self?.sessionGate?.complete()
      }
      self.phpickerAdapter = adapter
      picker.delegate = adapter
      applyPresentationStyle(to: picker, isCamera: false)

      viewController.present(picker, animated: true)
      gate.bind(continuation: continuation, to: picker) { [weak self] in
        self?.sessionGate?.cancel()
      }
    }

    gate.invalidate()
    sessionGate = nil

    let pickerResults = pendingPHPickerResults
    pendingPHPickerResults = []

    phpickerAdapter = nil

    if pickerResults.isEmpty {
      if configuration.allowsEmptySelection { return [] }
      throw FKPhotoPickerError.cancelled
    }

    let limit = configuration.selection.effectiveLimit
    if pickerResults.count > limit {
      switch configuration.selection.overflowBehavior {
      case .fail:
        throw FKPhotoPickerError.selectionLimitExceeded(selected: pickerResults.count, limit: limit)
      case .takeFirst:
        let trimmed = Array(pickerResults.prefix(configuration.selection.overflowTrimLimit))
        return try await processPickerResults(trimmed)
      }
    }

    return try await processPickerResults(pickerResults)
  }

  private func processPickerResults(_ results: [PHPickerResult]) async throws -> [FKPhotoPickerResult] {
    state = .processing
    let items = try await FKPhotoPickerInputExtractor.items(from: results, configuration: configuration)
    if items.isEmpty, !configuration.allowsEmptySelection {
      throw FKPhotoPickerError.cancelled
    }
    return try await FKPhotoProcessingPipeline.processItems(
      items,
      configuration: configuration,
      tempStore: tempStore,
      progressHandler: progressHandler
    )
  }

  // MARK: - Camera

  private func presentCamera(
    from viewController: UIViewController,
    source: FKPhotoPickerSource
  ) async throws -> [FKPhotoPickerResult] {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      throw FKPhotoPickerError.cameraUnavailable
    }

    let device = cameraDevice(for: source, configuration: configuration.camera)
    guard UIImagePickerController.isCameraDeviceAvailable(device) else {
      throw FKPhotoPickerError.cameraUnavailable
    }

    let gate = FKPhotoPickerSessionGate()
    sessionGate = gate

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.mediaTypes = imagePickerMediaTypes(for: configuration.mediaTypes)
      picker.allowsEditing = configuration.camera.allowsEditing
      picker.showsCameraControls = configuration.camera.showsCameraControls
      picker.cameraDevice = device
      if let flashMode = configuration.camera.flashMode {
        picker.cameraFlashMode = flashMode
      }
      if configuration.video.maximumDuration > 0 {
        picker.videoMaximumDuration = configuration.video.maximumDuration
      }

      let adapter = FKImagePickerDelegateAdapter { [weak self] result in
        switch result {
        case let .success(info):
          self?.pendingImagePickerInfo = info
          self?.sessionGate?.complete()
        case let .failure(error):
          if case FKPhotoPickerError.cancelled = error {
            self?.sessionGate?.cancel()
          } else {
            self?.sessionGate?.fail(with: error)
          }
        }
      }
      self.imagePickerAdapter = adapter
      picker.delegate = adapter
      applyPresentationStyle(to: picker, isCamera: true)

      viewController.present(picker, animated: true)
      gate.bind(continuation: continuation, to: picker) { [weak self] in
        self?.sessionGate?.cancel()
      }
    }

    gate.invalidate()
    sessionGate = nil

    guard let info = pendingImagePickerInfo else {
      throw FKPhotoPickerError.cancelled
    }
    pendingImagePickerInfo = nil

    imagePickerAdapter = nil
    state = .processing
    let item = try FKPhotoPickerInputExtractor.item(from: info)
    let processed = try await FKPhotoProcessingPipeline.processItems(
      [item],
      configuration: configuration,
      tempStore: tempStore,
      progressHandler: progressHandler
    )
    return processed
  }

  // MARK: - Presentation

  private func applyPresentationStyle(to viewController: UIViewController, isCamera: Bool) {
    let style = resolvedPresentationStyle(isCamera: isCamera)
    switch style {
    case .fullScreen:
      viewController.modalPresentationStyle = .fullScreen
    case .pageSheet:
      viewController.modalPresentationStyle = .pageSheet
    case .popover:
      viewController.modalPresentationStyle = .popover
      if let popover = viewController.popoverPresentationController, let popoverAnchor {
        switch popoverAnchor {
        case let .sourceView(sourceView, sourceRect):
          popover.sourceView = sourceView
          popover.sourceRect = sourceRect ?? sourceView.bounds
        case let .barButtonItem(item):
          popover.barButtonItem = item
        }
      }
    case .automatic:
      viewController.modalPresentationStyle = isCamera ? .fullScreen : .pageSheet
    }
  }

  private func resolvedPresentationStyle(isCamera: Bool) -> FKPhotoPickerPresentation {
    switch configuration.presentation.style {
    case .automatic:
      return isCamera ? .fullScreen : .pageSheet
    default:
      return configuration.presentation.style
    }
  }

  // MARK: - Mapping

  private func phpFilter(for mediaTypes: FKPhotoPickerMediaTypes) -> PHPickerFilter {
    let hasImages = mediaTypes.contains(.images)
    let hasVideos = mediaTypes.contains(.videos)
    let hasLive = mediaTypes.contains(.livePhotos)

    if hasImages, hasVideos, hasLive {
      return .any(of: [.images, .videos, .livePhotos])
    }
    if hasImages, hasVideos {
      return .any(of: [.images, .videos])
    }
    if hasImages, hasLive {
      return .any(of: [.images, .livePhotos])
    }
    if hasVideos, hasLive {
      return .any(of: [.videos, .livePhotos])
    }
    if hasVideos { return .videos }
    if hasLive { return .livePhotos }
    return .images
  }

  private func imagePickerMediaTypes(for mediaTypes: FKPhotoPickerMediaTypes) -> [String] {
    var output: [String] = []
    if mediaTypes.contains(.images) || mediaTypes.contains(.livePhotos) {
      output.append(UTType.image.identifier)
    }
    if mediaTypes.contains(.videos) {
      output.append(UTType.movie.identifier)
    }
    if output.isEmpty {
      output.append(UTType.image.identifier)
    }
    return output
  }

  private func cameraDevice(
    for source: FKPhotoPickerSource,
    configuration: FKPhotoPickerCameraOptions
  ) -> UIImagePickerController.CameraDevice {
    switch source {
    case .cameraFront:
      return .front
    case .cameraBack:
      return .rear
    default:
      return configuration.cameraDevice ?? .rear
    }
  }

  // MARK: - Completion

  private func finishSession() {
    state = .idle
    retainSelf = nil
    sourceChooserDismissObserver = nil
    progressHandler = nil
    popoverAnchor = nil
  }
}
