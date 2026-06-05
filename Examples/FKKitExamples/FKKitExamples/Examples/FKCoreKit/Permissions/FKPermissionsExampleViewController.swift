import FKCoreKit
import UIKit

/// Interactive catalog of `FKPermissions` APIs and every `FKPermissionKind`.
/// All copy and labels are English-only for international teams.
final class FKPermissionsExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  /// Fixed output panel (same layout contract as `FKAsyncExampleViewController`).
  private let logView = UITextView()
  private var statusObservation: FKPermissionObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKPermissions"
    view.backgroundColor = .systemBackground
    buildLayout()
    buildSections()
    appendLog("FKPermissions playground ready. Each button exercises one API shape or permission kind.")
    appendLog("Tip: use “Start observing…” then grant/deny or background/resume the app to see status callbacks.")
  }

  deinit {
    statusObservation?.invalidate()
  }

  // MARK: - Layout

  /// Mirrors `FKAsyncExampleViewController.buildLayout`: scrollable actions on top (~52% of safe area), log pinned to bottom.
  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.axis = .vertical
    contentStack.spacing = 8

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func buildSections() {
    addSectionHeading("Status (no system prompt)")
    addActionButton("async status — Camera") { [weak self] in self?.runAsyncStatusCamera() }
    addActionButton("completion status — Notifications") { [weak self] in self?.runCompletionStatusNotifications() }

    addSectionHeading("Single request — async/await (by kind)")
    addActionButton("Camera — with pre-prompt") { [weak self] in self?.runRequestCameraWithPrePrompt() }
    addActionButton("Photo library — read access") { [weak self] in self?.runRequestPhotoRead() }
    addActionButton("Photo library — add-only (save without full read)") { [weak self] in self?.runRequestPhotoAddOnly() }
    addActionButton("Microphone") { [weak self] in self?.runRequestMicrophone() }
    addActionButton("Location — When In Use") { [weak self] in self?.runRequestLocationWhenInUse() }
    addActionButton("Location — Always") { [weak self] in self?.runRequestLocationAlways() }
    addActionButton("Location — temporary full accuracy (needs When-In-Use first)") { [weak self] in
      self?.runRequestTemporaryFullAccuracy()
    }
    addActionButton("Notifications") { [weak self] in self?.runRequestNotificationsAsync() }
    addActionButton("Bluetooth") { [weak self] in self?.runRequestBluetooth() }
    addActionButton("Calendar") { [weak self] in self?.runRequestCalendar() }
    addActionButton("Reminders") { [weak self] in self?.runRequestReminders() }
    addActionButton("Media library (Apple Music)") { [weak self] in self?.runRequestMediaLibrary() }
    addActionButton("Speech recognition") { [weak self] in self?.runRequestSpeech() }
    addActionButton("App Tracking Transparency") { [weak self] in self?.runRequestAppTracking() }

    addSectionHeading("Single request — closure completion API")
    addActionButton("Microphone — completion handler (non-async call sites)") { [weak self] in
      self?.runRequestMicrophoneClosure()
    }

    addSectionHeading("Explicit FKPermissionRequest model")
    addActionButton("Build FKPermissionRequest — camera + custom pre-prompt copy") { [weak self] in
      self?.runExplicitPermissionRequestModel()
    }

    addSectionHeading("Pre-prompt cancellation")
    addActionButton("Pre-prompt — tap “Not now” to surface .prePromptCancelled") { [weak self] in
      self?.runPrePromptCancelDemo()
    }

    addSectionHeading("Batch requests (sequential on main actor)")
    addActionButton("Batch — [FKPermissionKind] convenience") { [weak self] in self?.runBatchKinds() }
    addActionButton("Batch — [FKPermissionRequest] mixed pre-prompts") { [weak self] in self?.runBatchRequests() }
    addActionButton("Batch — completion handler (maps kinds → results)") { [weak self] in self?.runBatchCompletionAPI() }

    addSectionHeading("Observe status + Settings")
    addActionButton("Start observing status changes (keep token alive)") { [weak self] in self?.startObserving() }
    addActionButton("Stop observing (invalidate token)") { [weak self] in self?.stopObserving() }
    addActionButton("Open system Settings for this app") { [weak self] in self?.runOpenSettings() }

    addSectionHeading("Production-style branching")
    addActionButton("Inspect Camera — denied vs notDetermined vs granted") { [weak self] in self?.runInspectCameraFlow() }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  private func addSectionHeading(_ text: String) {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    contentStack.addArrangedSubview(label)
    contentStack.setCustomSpacing(12, after: label)
  }

  private func addActionButton(_ title: String, handler: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    contentStack.addArrangedSubview(button)
  }

  // MARK: - Status

  private func runAsyncStatusCamera() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let status = await FKPermissions.shared.status(for: .camera)
      appendLog("[status async] camera → \(status.logLabel)")
    }
  }

  private func runCompletionStatusNotifications() {
    appendLog("[status completion] querying notifications…")
    FKPermissions.shared.status(for: .notifications) { [weak self] status in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.appendLog("[status completion] notifications → \(status.logLabel)")
      }
    }
  }

  // MARK: - Requests by kind

  private func runRequestCameraWithPrePrompt() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let prePrompt = FKPermissionPrePrompt(
        title: "Camera access",
        message: "This educational sheet appears before the system dialog.",
        confirmTitle: "Continue",
        cancelTitle: "Not now"
      )
      let result = await FKPermissions.shared.request(.camera, prePrompt: prePrompt)
      logPermissionResult(result, label: "camera + pre-prompt")
    }
  }

  private func runRequestPhotoRead() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.photoLibraryRead)
      logPermissionResult(result, label: "photoLibraryRead")
    }
  }

  private func runRequestPhotoAddOnly() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.photoLibraryAddOnly)
      logPermissionResult(result, label: "photoLibraryAddOnly")
    }
  }

  private func runRequestMicrophone() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.microphone)
      logPermissionResult(result, label: "microphone")
    }
  }

  private func runRequestLocationWhenInUse() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.locationWhenInUse)
      logPermissionResult(result, label: "locationWhenInUse")
    }
  }

  private func runRequestLocationAlways() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.locationAlways)
      logPermissionResult(result, label: "locationAlways")
    }
  }

  private func runRequestTemporaryFullAccuracy() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      appendLog("[location] requesting temporary full accuracy with Info.plist purpose key…")
      let result = await FKPermissions.shared.request(
        .locationTemporaryFullAccuracy,
        temporaryLocationPurposeKey: "FKLocationTemporaryFullAccuracyPurpose"
      )
      logPermissionResult(result, label: "locationTemporaryFullAccuracy")
    }
  }

  private func runRequestNotificationsAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.notifications)
      logPermissionResult(result, label: "notifications (async)")
    }
  }

  private func runRequestBluetooth() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.bluetooth)
      logPermissionResult(result, label: "bluetooth")
    }
  }

  private func runRequestCalendar() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.calendar)
      logPermissionResult(result, label: "calendar")
    }
  }

  private func runRequestReminders() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.reminders)
      logPermissionResult(result, label: "reminders")
    }
  }

  private func runRequestMediaLibrary() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.mediaLibrary)
      logPermissionResult(result, label: "mediaLibrary")
    }
  }

  private func runRequestSpeech() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.speechRecognition)
      logPermissionResult(result, label: "speechRecognition")
    }
  }

  private func runRequestAppTracking() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.appTracking)
      logPermissionResult(result, label: "appTracking")
    }
  }

  private func runRequestMicrophoneClosure() {
    appendLog("[request completion] microphone…")
    FKPermissions.shared.request(.microphone) { [weak self] result in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.logPermissionResult(result, label: "microphone (completion)")
      }
    }
  }

  private func runExplicitPermissionRequestModel() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let request = FKPermissionRequest(
        kind: .camera,
        prePrompt: FKPermissionPrePrompt(
          title: "Explicit model",
          message: "Built with FKPermissionRequest(…) instead of the shorthand overload.",
          confirmTitle: "OK",
          cancelTitle: "Cancel"
        ),
        temporaryLocationPurposeKey: nil
      )
      let result = await FKPermissions.shared.request(request)
      logPermissionResult(result, label: "FKPermissionRequest → camera")
    }
  }

  private func runPrePromptCancelDemo() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let prePrompt = FKPermissionPrePrompt(
        title: "Optional education sheet",
        message: "Choose “Walk away” to cancel before any system permission UI.",
        confirmTitle: "Continue to system UI",
        cancelTitle: "Walk away"
      )
      let result = await FKPermissions.shared.request(.microphone, prePrompt: prePrompt)
      logPermissionResult(result, label: "pre-prompt cancel demo")
      if case .prePromptCancelled = result.error {
        appendLog("Observed FKPermissionError.prePromptCancelled — flow stopped before system prompt.")
      }
    }
  }

  // MARK: - Batch

  private func runBatchKinds() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      appendLog("[batch kinds] sequential: microphone → notifications")
      let map = await FKPermissions.shared.request([.microphone, .notifications])
      for kind in [FKPermissionKind.microphone, .notifications] {
        if let r = map[kind] {
          let errSuffix = r.error.map { " \($0.logLabel)" } ?? ""
          appendLog(" - \(kind.logLabel): \(r.status.logLabel) granted=\(r.isGranted)\(errSuffix)")
        }
      }
    }
  }

  private func runBatchRequests() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      appendLog("[batch FKPermissionRequest] photo read (no pre-prompt) then camera (with pre-prompt)")
      let requests: [FKPermissionRequest] = [
        FKPermissionRequest(kind: .photoLibraryRead),
        FKPermissionRequest(
          kind: .camera,
          prePrompt: FKPermissionPrePrompt(
            title: "Second step",
            message: "Batch runs sequentially; this sheet appears before the camera system dialog.",
            confirmTitle: "Continue",
            cancelTitle: "Skip"
          )
        ),
      ]
      let map = await FKPermissions.shared.request(requests)
      for req in requests {
        if let r = map[req.kind] {
          let errSuffix = r.error.map { " \($0.logLabel)" } ?? ""
          appendLog(" - \(req.kind.logLabel): \(r.status.logLabel) granted=\(r.isGranted)\(errSuffix)")
        }
      }
    }
  }

  private func runBatchCompletionAPI() {
    appendLog("[batch completion] scheduling Task → FKPermissions.request([…]) { … }")
    let requests = [
      FKPermissionRequest(kind: .notifications),
      FKPermissionRequest(kind: .photoLibraryRead),
    ]
    FKPermissions.shared.request(requests) { [weak self] map in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.appendLog("[batch completion] finished")
        for req in requests {
          if let r = map[req.kind] {
            let errSuffix = r.error.map { " \($0.logLabel)" } ?? ""
            self.appendLog(" - \(req.kind.logLabel): \(r.status.logLabel)\(errSuffix)")
          }
        }
      }
    }
  }

  // MARK: - Observation & settings

  private func startObserving() {
    statusObservation?.invalidate()
    statusObservation = FKPermissions.shared.observeStatusChanges { [weak self] kind, status in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.appendLog("[observe] \(kind.logLabel) → \(status.logLabel)")
      }
    }
    appendLog("Observation registered. Background/resume the app or change permissions to refresh snapshots.")
  }

  private func stopObserving() {
    statusObservation?.invalidate()
    statusObservation = nil
    appendLog("Observation invalidated.")
  }

  private func runOpenSettings() {
    let ok = FKPermissions.shared.openAppSettings()
    appendLog(ok ? "openAppSettings() returned true." : "openAppSettings() returned false.")
  }

  // MARK: - Inspect flow

  private func runInspectCameraFlow() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let status = await FKPermissions.shared.status(for: .camera)
      appendLog("[inspect camera] current status: \(status.logLabel)")
      switch status {
      case .denied, .restricted, .deviceDisabled:
        presentDeniedAlert(
          title: "Camera unavailable",
          message: "Enable Camera in Settings to continue this flow."
        )
      case .authorized, .limited, .provisional, .ephemeral:
        appendLog("Camera already authorized — continue into capture APIs.")
      case .notDetermined:
        let result = await FKPermissions.shared.request(.camera)
        logPermissionResult(result, label: "inspect → first request")
      }
    }
  }

  // MARK: - Alerts & logging

  private func logPermissionResult(_ result: FKPermissionResult, label: String) {
    let err = result.error.map { " error=\($0.logLabel)" } ?? ""
    appendLog("[\(label)] status=\(result.status.logLabel) isGranted=\(result.isGranted)\(err)")
    switch result.status {
    case .denied, .restricted, .deviceDisabled:
      presentDeniedAlert(
        title: "Permission blocked",
        message: "Open Settings to adjust \(label.replacingOccurrences(of: "_", with: " "))."
      )
    case .notDetermined, .authorized, .limited, .provisional, .ephemeral:
      break
    }
  }

  private func presentDeniedAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(
      UIAlertAction(title: "Open Settings", style: .default) { _ in
        _ = FKPermissions.shared.openAppSettings()
      }
    )
    present(alert, animated: true)
  }

  private func clearLog() {
    logView.text = ""
    appendLog("Log cleared.")
  }

  private func appendLog(_ message: String) {
    let ts = DateFormatter.fkPermissionsLogFormatter.string(from: Date())
    let line = "[\(ts)] \(message)\n"
    logView.text.append(line)
    let end = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(end)
  }
}

// MARK: - Formatting

private extension FKPermissionKind {
  var logLabel: String {
    switch self {
    case .camera: return "camera"
    case .photoLibraryRead: return "photoLibraryRead"
    case .photoLibraryAddOnly: return "photoLibraryAddOnly"
    case .microphone: return "microphone"
    case .locationWhenInUse: return "locationWhenInUse"
    case .locationAlways: return "locationAlways"
    case .locationTemporaryFullAccuracy: return "locationTemporaryFullAccuracy"
    case .notifications: return "notifications"
    case .bluetooth: return "bluetooth"
    case .calendar: return "calendar"
    case .reminders: return "reminders"
    case .mediaLibrary: return "mediaLibrary"
    case .speechRecognition: return "speechRecognition"
    case .appTracking: return "appTracking"
    }
  }
}

private extension FKPermissionStatus {
  var logLabel: String {
    switch self {
    case .notDetermined: return "notDetermined"
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .limited: return "limited"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    case .deviceDisabled: return "deviceDisabled"
    }
  }
}

private extension FKPermissionError {
  var logLabel: String {
    switch self {
    case .prePromptCancelled: return "prePromptCancelled"
    case .unavailable: return "unavailable"
    case let .custom(message): return "custom(\(message))"
    }
  }
}

private extension DateFormatter {
  static let fkPermissionsLogFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "HH:mm:ss.SSS"
    return f
  }()
}
