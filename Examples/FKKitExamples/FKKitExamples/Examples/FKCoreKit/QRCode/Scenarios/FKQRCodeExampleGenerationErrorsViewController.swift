import FKCoreKit
import UIKit

final class FKQRCodeExampleGenerationErrorsViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Generation Errors"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("emptyContent — whitespace-only string") { [weak self] in
      self?.generateAndPreview(label: "error.empty", content: "   \n  ")
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("contentTooLong — exceeds 2953 UTF-8 bytes") { [weak self] in
      let payload = String(repeating: "A", count: FKQRCodeGenerator.maxContentBytes + 1)
      self?.generateAndPreview(label: "error.tooLong", content: payload)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeError",
        description: "Typed errors surface through LocalizedError. Host apps should map these to user-facing copy.",
        body: body
      )
    )
    addClearLogButton()
  }
}
