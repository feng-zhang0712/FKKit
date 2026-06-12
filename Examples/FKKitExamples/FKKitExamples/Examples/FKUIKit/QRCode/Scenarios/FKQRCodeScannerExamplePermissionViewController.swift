import FKCoreKit
import FKUIKit
import UIKit

final class FKQRCodeScannerExamplePermissionViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Permissions"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Camera with FKPermissionPrePrompt") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.permissionPrePrompt = FKPermissionPrePrompt(
        title: "Camera for QR Scanning",
        message: "FKQRCode needs camera access to read QR codes. You can change this later in Settings.",
        confirmTitle: "Continue",
        cancelTitle: "Not Now"
      )
      self?.presentScanner(label: "permission.prePrompt", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Open Settings — revoke camera to test denied UI") {
      _ = FKPermissions.shared.openAppSettings()
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKPermissions + FKEmptyState",
        description: "Denied or restricted camera access shows FKEmptyStateConfiguration.scenario(.noPermission) with an Open Settings action. Pre-prompt runs before the system dialog when status is .notDetermined.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption(
        """
        To test denied state: Settings → Privacy & Security → Camera → FKKitExamples → Off, then open the scanner again.
        """
      )
    )
    addClearLogButton()
  }
}
