import FKUIKit
import UIKit

final class FKQRCodeScannerExampleMockViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Mock Scanner"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Default mock payload") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.simulatorMockRawValue = "https://example.com/mock-default"
      self?.presentScanner(label: "mock.default", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Custom deep link payload") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.simulatorMockRawValue = "myapp://order/ORDER-7788"
      self?.presentScanner(label: "mock.deeplink", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeMockScannerView",
        description: "When no camera device is available (Simulator), an internal placeholder replaces the preview and offers Simulate Scan.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Physical devices with a camera use the live preview instead of this mock UI.")
    )
    addClearLogButton()
  }
}
