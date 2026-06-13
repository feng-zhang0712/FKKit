import FKUIKit
import UIKit

final class FKQRCodeScannerExampleBasicsViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scan Basics"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Present default scanner") { [weak self] in
      self?.presentScanner(label: "scan.default")
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Present with haptics off") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.hapticsOnSuccess = false
      config.announcesScanSuccess = false
      self?.presentScanner(label: "scan.noFeedback", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeScannerViewController",
        description: "Full-screen modal with camera preview, overlay, close button, and delegate callbacks. Generate a QR from FKCoreKit → QRCode examples and scan it on a physical device.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Requires NSCameraUsageDescription in Info.plist (already set for this demo app).")
    )
    addClearLogButton()
  }
}
