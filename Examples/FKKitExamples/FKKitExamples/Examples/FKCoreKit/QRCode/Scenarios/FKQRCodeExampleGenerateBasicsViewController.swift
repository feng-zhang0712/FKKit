import FKCoreKit
import UIKit

final class FKQRCodeExampleGenerateBasicsViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Generate Basics"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Generate payment URL (default options)") { [weak self] in
      self?.generateAndPreview(
        label: "payment.default",
        content: "https://example.com/pay?id=demo-001"
      )
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Generate plain text") { [weak self] in
      self?.generateAndPreview(
        label: "text.default",
        content: "FKKit QR demo — scan me on a device"
      )
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeGenerator.makeImage",
        description: "Uses CIQRCodeGenerator with default 256×256 output. Scan the preview with the Scanner examples on a physical device.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Tip: pair with FKUIKit → QRCode Scanner → Scan basics on another phone.")
    )
    addClearLogButton()
    generateAndPreview(label: "initial", content: "https://example.com/pay?id=demo-001")
  }
}
