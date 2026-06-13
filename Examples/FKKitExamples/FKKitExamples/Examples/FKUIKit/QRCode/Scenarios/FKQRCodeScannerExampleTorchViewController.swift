import FKUIKit
import UIKit

final class FKQRCodeScannerExampleTorchViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Torch"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("showsTorchButton = true (default)") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.showsTorchButton = true
      self?.presentScanner(label: "torch.on", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("showsTorchButton = false") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.showsTorchButton = false
      self?.presentScanner(label: "torch.hidden", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "Torch toggle",
        description: "FKButton torch control appears when AVCaptureDevice.hasTorch is true. Torch is forced off when the scanner dismisses.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Test on a physical device in low light. Simulator uses the mock scanner without torch.")
    )
    addClearLogButton()
  }
}
