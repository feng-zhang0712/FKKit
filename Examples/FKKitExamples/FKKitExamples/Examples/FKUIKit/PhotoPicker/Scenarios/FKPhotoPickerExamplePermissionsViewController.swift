import FKCoreKit
import FKUIKit
import UIKit

final class FKPhotoPickerExamplePermissionsViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Permission Flows"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Camera with pre-prompt") { [weak self] in
      var config = FKPhotoPickerConfiguration.documentScan()
      config.permission.cameraPrePrompt = FKPermissionPrePrompt(
        title: "Camera access",
        message: "We use the camera to capture documents for this demo."
      )
      self?.pick(label: "permission.cameraPrePrompt", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("checksPhotoLibrary = true (legacy read)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.permission.checksPhotoLibrary = true
      self?.pick(label: "permission.libraryRead", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("opensSettingsOnDenied = true") { [weak self] in
      var config = FKPhotoPickerConfiguration.documentScan()
      config.permission.opensSettingsOnDenied = true
      self?.pick(label: "permission.openSettings", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Present limited library management") { [weak self] in
      guard let self else { return }
      picker.presentLimitedLibraryManagement(from: self)
      log("presentLimitedLibraryManagement(from:) — requires .limited photo access.")
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Show permission-denied empty state pattern") { [weak self] in
      self?.presentPermissionDeniedEmptyState()
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoPickerPermissionPolicy",
        description: "PHPicker skips full-library read permission by default. Use checksPhotoLibrary when you need explicit read access or legacy flows. Catch .permissionDenied to show fallback UI.",
        body: body
      )
    )
    addClearLogButton()
  }

  private func presentPermissionDeniedEmptyState() {
    var config = FKEmptyStateConfiguration(
      phase: .empty,
      type: .permissionDenied,
      title: "Camera access needed",
      description: "Enable camera access in Settings to capture photos.",
      primaryActionTitle: "Open Settings",
      primaryActionID: "openSettings"
    )
    config.actions.secondary = FKEmptyStateAction(id: "dismiss", title: "Not now", kind: .secondary)

    let empty = FKEmptyStateView()
    empty.translatesAutoresizingMaskIntoConstraints = false
    empty.apply(config)
    empty.actionHandler = { action in
      if action.id == "openSettings" {
        FKPermissions.shared.openAppSettings()
      }
    }

    let sheet = UIViewController()
    sheet.view.backgroundColor = .systemBackground
    sheet.view.addSubview(empty)
    NSLayoutConstraint.activate([
      empty.centerXAnchor.constraint(equalTo: sheet.view.centerXAnchor),
      empty.centerYAnchor.constraint(equalTo: sheet.view.centerYAnchor),
      empty.leadingAnchor.constraint(greaterThanOrEqualTo: sheet.view.leadingAnchor, constant: 24),
      empty.trailingAnchor.constraint(lessThanOrEqualTo: sheet.view.trailingAnchor, constant: -24),
    ])
    sheet.modalPresentationStyle = .pageSheet
    present(sheet, animated: true)
    log("Presented FKEmptyState fallback for .permissionDenied UX.")
  }
}
