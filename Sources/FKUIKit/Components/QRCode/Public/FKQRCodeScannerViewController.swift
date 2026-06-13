import AVFoundation
import FKCoreKit
import SafariServices
import UIKit

/// Full-screen QR code scanner with camera preview, overlay, torch, and permission handling.
@MainActor
public final class FKQRCodeScannerViewController: UIViewController {
  /// Scanner behavior and presentation options.
  public var configuration: FKQRCodeScannerConfiguration {
    didSet { applyConfigurationUpdates(from: oldValue) }
  }

  /// Receives scan results, cancellation, and errors.
  public weak var delegate: FKQRCodeScannerDelegate?

  private let previewContainer = UIView()
  private let overlayView = FKQRCodeOverlayView()
  private let hintLabel = UILabel()
  private let closeButton = FKButton()
  private let torchButton = FKButton()
  private let emptyStateHost = UIView()

  private let captureController = FKQRCodeCaptureSessionController()
  private var mockScannerView: FKQRCodeMockScannerView?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var isTorchOn = false
  private var hasStartedSession = false
  private var lastRawPayload: String?
  private var duplicateResetDebouncer: FKDebouncer?
  private var asyncScanCoordinator: FKQRCodeScannerAsyncCoordinator?

  private var usesMockScanner: Bool {
    !FKQRCodeCaptureSessionController.isCameraAvailable
  }

  /// Creates a scanner view controller.
  public init(configuration: FKQRCodeScannerConfiguration = .default) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    captureController.turnTorchOff()
    captureController.stopRunning()
  }

  // MARK: - Lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    configureChrome()
    configureCaptureCallbacks()
    overlayView.apply(style: configuration.overlayStyle)
    Task { await startFlow() }
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updatePreviewOrientation()
    if hasStartedSession {
      captureController.startRunning()
    }
  }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureController.turnTorchOff()
    isTorchOn = false
    updateTorchButtonAppearance()
    captureController.stopRunning()
    fk_clearEmptyStateActionObservers()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = previewContainer.bounds
    captureController.updatePreviewFrame(previewContainer.bounds)
  }

  public override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.updatePreviewOrientation()
    })
  }

  // MARK: - Public async API

  /// Presents a scanner modally and suspends until a payload is scanned or the user cancels.
  public static func scan(
    from presenter: UIViewController,
    configuration: FKQRCodeScannerConfiguration = .default
  ) async throws -> FKQRCodePayload {
    try await withCheckedThrowingContinuation { continuation in
      let scanner = FKQRCodeScannerViewController(configuration: configuration)
      let coordinator = FKQRCodeScannerAsyncCoordinator(
        continuation: continuation,
        scanner: scanner
      )
      scanner.asyncScanCoordinator = coordinator
      scanner.delegate = coordinator
      presenter.present(scanner, animated: true)
    }
  }

  // MARK: - Setup

  private func configureChrome() {
    previewContainer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(previewContainer)

    overlayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlayView)

    emptyStateHost.translatesAutoresizingMaskIntoConstraints = false
    emptyStateHost.isHidden = true
    view.addSubview(emptyStateHost)

    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    hintLabel.font = .preferredFont(forTextStyle: .footnote)
    hintLabel.textColor = .white
    hintLabel.textAlignment = .center
    hintLabel.numberOfLines = 0
    hintLabel.text = FKUIKitI18n.string("fkuikit.qrcode.scan_hint")
    view.addSubview(hintLabel)

    configureIconButton(
      closeButton,
      systemName: "xmark",
      accessibilityLabel: FKUIKitI18n.string("fkuikit.qrcode.close_a11y"),
      action: #selector(handleCloseTapped)
    )
    configureIconButton(
      torchButton,
      systemName: "bolt.slash.fill",
      accessibilityLabel: FKUIKitI18n.string("fkuikit.qrcode.torch_a11y"),
      action: #selector(handleTorchTapped)
    )
    torchButton.isHidden = !configuration.showsTorchButton

    NSLayoutConstraint.activate([
      previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
      previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      overlayView.topAnchor.constraint(equalTo: view.topAnchor),
      overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      emptyStateHost.topAnchor.constraint(equalTo: view.topAnchor),
      emptyStateHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      emptyStateHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      emptyStateHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

      torchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      torchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      hintLabel.bottomAnchor.constraint(equalTo: torchButton.topAnchor, constant: -16),
    ])
  }

  private func configureIconButton(
    _ button: FKButton,
    systemName: String,
    accessibilityLabel: String,
    action: Selector
  ) {
    button.translatesAutoresizingMaskIntoConstraints = false
    button.content = .imageOnly
    var appearance = FKButtonAppearance.filled(backgroundColor: UIColor.black.withAlphaComponent(0.55))
    appearance.cornerStyle = .init(corner: .fixed(22))
    appearance.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
    button.setAppearances(.init(normal: appearance))
    button.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    var image = FKButtonImageConfiguration(
      systemName: systemName,
      symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold),
      tintColor: .white
    )
    image.accessibilityLabel = accessibilityLabel
    button.setImage(image, slot: .center, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    view.addSubview(button)
  }

  private func configureCaptureCallbacks() {
    captureController.onMetadataString = { [weak self] value in
      self?.handleDetectedRawValue(value)
    }
  }

  private func applyConfigurationUpdates(from oldValue: FKQRCodeScannerConfiguration) {
    overlayView.apply(style: configuration.overlayStyle)
    torchButton.isHidden = !configuration.showsTorchButton
    if oldValue.cooldownInterval != configuration.cooldownInterval {
      duplicateResetDebouncer = FKDebouncer(interval: configuration.cooldownInterval, queue: .main)
    }
    if oldValue.simulatorMockRawValue != configuration.simulatorMockRawValue {
      mockScannerView?.removeFromSuperview()
      mockScannerView = nil
      if usesMockScanner {
        showMockScanner()
      }
    }
  }

  // MARK: - Flow

  private func startFlow() async {
    if usesMockScanner {
      showMockScanner()
      return
    }

    let status = await FKPermissions.shared.status(for: .camera)
    switch status {
    case .authorized:
      await startCameraSession()
    case .notDetermined:
      await requestCameraPermission()
    case .denied, .restricted, .deviceDisabled, .limited, .provisional, .ephemeral:
      showPermissionDeniedEmptyState()
    }
  }

  private func requestCameraPermission() async {
    let result = await FKPermissions.shared.request(
      .camera,
      prePrompt: configuration.permissionPrePrompt
    )
    if result.error == .prePromptCancelled {
      dismissScanner(reportCancel: true)
      return
    }
    guard result.isGranted else {
      showPermissionDeniedEmptyState()
      return
    }
    await startCameraSession()
  }

  private func startCameraSession() async {
    guard captureController.configureIfNeeded() else {
      if usesMockScanner {
        showMockScanner()
      } else {
        handleScannerFailure(.sessionConfigurationFailed)
      }
      return
    }

    emptyStateHost.isHidden = true
    emptyStateHost.fk_hideEmptyState(animated: false)
    previewContainer.isHidden = false
    overlayView.isHidden = false
    hintLabel.isHidden = false

    previewLayer = captureController.attachPreviewLayer(to: previewContainer.layer)
    updatePreviewOrientation()
    captureController.startRunning()
    hasStartedSession = true
    updateTorchAvailability()
  }

  private func showMockScanner() {
    guard mockScannerView == nil else { return }

    previewContainer.isHidden = true
    overlayView.isHidden = true
    hintLabel.isHidden = true
    torchButton.isHidden = true

    let mockView = FKQRCodeMockScannerView(rawValue: configuration.simulatorMockRawValue)
    mockView.translatesAutoresizingMaskIntoConstraints = false
    mockView.onSimulateScan = { [weak self] raw in
      self?.handleDetectedRawValue(raw)
    }
    view.insertSubview(mockView, belowSubview: closeButton)
    NSLayoutConstraint.activate([
      mockView.topAnchor.constraint(equalTo: view.topAnchor),
      mockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      mockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    mockScannerView = mockView
  }

  private func showPermissionDeniedEmptyState() {
    previewContainer.isHidden = true
    overlayView.isHidden = true
    hintLabel.isHidden = true
    torchButton.isHidden = true
    emptyStateHost.isHidden = false

    var model = FKEmptyStateConfiguration.scenario(.noPermission)
    model.content.title = FKUIKitI18n.string("fkuikit.qrcode.permission.title")
    model.content.description = FKUIKitI18n.string("fkuikit.qrcode.permission.description")
    model.actions = .primary(
      FKUIKitI18n.string("fkuikit.qrcode.permission.open_settings"),
      id: "open_settings"
    )

    emptyStateHost.fk_applyEmptyState(model) { action in
      guard action.id == "open_settings" else { return }
      _ = FKPermissions.shared.openAppSettings()
    }
  }

  // MARK: - Detection

  private func handleDetectedRawValue(_ rawValue: String) {
    guard shouldAccept(rawValue: rawValue) else { return }

    lastRawPayload = rawValue
    scheduleDuplicateReset()

    let payload = FKQRCodeParser.parse(rawValue)
    FKLogD("FKQRCode scan succeeded", metadata: ["length": String(rawValue.count)])

    if configuration.hapticsOnSuccess {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    if configuration.announcesScanSuccess {
      UIAccessibility.post(
        notification: .announcement,
        argument: FKUIKitI18n.string("fkuikit.qrcode.scan_success_a11y")
      )
    }

    delegate?.qrCodeScanner(self, didScan: payload)
    applyNavigationPolicy(for: payload)
    mockScannerView?.showScanSucceeded()

    if configuration.scanMode == .once {
      captureController.stopRunning()
    }
  }

  private func shouldAccept(rawValue: String) -> Bool {
    guard !rawValue.isEmpty else { return false }
    if configuration.allowsMultipleCallbacks { return true }
    if let lastRawPayload, lastRawPayload == rawValue {
      return false
    }
    return true
  }

  private func scheduleDuplicateReset() {
    if duplicateResetDebouncer == nil {
      duplicateResetDebouncer = FKDebouncer(interval: configuration.cooldownInterval, queue: .main)
    }
    duplicateResetDebouncer?.signal { [weak self] in
      Task { @MainActor in
        self?.lastRawPayload = nil
      }
    }
  }

  private func applyNavigationPolicy(for payload: FKQRCodePayload) {
    guard case let .url(url) = payload else { return }
    switch configuration.navigationPolicy {
    case .callbackOnly:
      break
    case .openHTTPInApp:
      guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
      present(SFSafariViewController(url: url), animated: true)
    case .openExternally:
      UIApplication.shared.open(url)
    }
  }

  // MARK: - Actions

  @objc private func handleCloseTapped() {
    dismissScanner(reportCancel: true)
  }

  @objc private func handleTorchTapped() {
    isTorchOn.toggle()
    captureController.setTorchEnabled(isTorchOn)
    updateTorchButtonAppearance()
  }

  private func updateTorchAvailability() {
    let hasTorch = AVCaptureDevice.default(for: .video)?.hasTorch == true
    torchButton.isHidden = !configuration.showsTorchButton || !hasTorch || usesMockScanner
  }

  private func updateTorchButtonAppearance() {
    let symbol = isTorchOn ? "bolt.fill" : "bolt.slash.fill"
    var image = FKButtonImageConfiguration(
      systemName: symbol,
      symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold),
      tintColor: .white
    )
    image.accessibilityLabel = FKUIKitI18n.string("fkuikit.qrcode.torch_a11y")
    torchButton.setImage(image, slot: .center, for: .normal)
  }

  private func updatePreviewOrientation() {
    captureController.updateVideoOrientation(currentVideoOrientation())
  }

  private func currentVideoOrientation() -> AVCaptureVideoOrientation {
    guard let orientation = view.window?.windowScene?.interfaceOrientation else {
      return .portrait
    }
    switch orientation {
    case .portrait: return .portrait
    case .portraitUpsideDown: return .portraitUpsideDown
    case .landscapeLeft: return .landscapeLeft
    case .landscapeRight: return .landscapeRight
    default: return .portrait
    }
  }

  private func handleScannerFailure(_ error: FKQRCodeScannerError) {
    delegate?.qrCodeScanner(self, didFail: error)
    asyncScanCoordinator?.fail(error)
  }

  private func dismissScanner(reportCancel: Bool) {
    captureController.turnTorchOff()
    captureController.stopRunning()
    dismiss(animated: true) { [weak self] in
      guard reportCancel, let self else { return }
      self.delegate?.qrCodeScannerDidCancel(self)
      self.asyncScanCoordinator?.cancel()
    }
  }
}

// MARK: - Async coordinator

@MainActor
private final class FKQRCodeScannerAsyncCoordinator: NSObject, FKQRCodeScannerDelegate {
  private var continuation: CheckedContinuation<FKQRCodePayload, Error>?

  init(
    continuation: CheckedContinuation<FKQRCodePayload, Error>,
    scanner _: FKQRCodeScannerViewController
  ) {
    self.continuation = continuation
  }

  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didScan payload: FKQRCodePayload) {
    resumeOnce(with: .success(payload))
    scanner.dismiss(animated: true)
  }

  func qrCodeScannerDidCancel(_ scanner: FKQRCodeScannerViewController) {
    cancel()
  }

  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError) {
    fail(error)
  }

  func cancel() {
    resumeOnce(with: .failure(CancellationError()))
  }

  func fail(_ error: FKQRCodeScannerError) {
    resumeOnce(with: .failure(error))
  }

  private func resumeOnce(with result: Result<FKQRCodePayload, Error>) {
    guard let continuation else { return }
    self.continuation = nil
    switch result {
    case let .success(payload):
      continuation.resume(returning: payload)
    case let .failure(error):
      continuation.resume(throwing: error)
    }
  }
}
