import FKCoreKit
import UIKit

final class FKQRCodeExampleColorsAndSizeViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Colors & Size"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Brand colors · 512×512") { [weak self] in
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 512, height: 512)
      options.foregroundColor = UIColor(red: 0.10, green: 0.22, blue: 0.55, alpha: 1)
      options.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1)
      options.correctionLevel = .H
      self?.generateAndPreview(
        label: "brand.512",
        content: "https://example.com/brand",
        options: options
      )
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Compact 128×128 · inverted") { [weak self] in
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 128, height: 128)
      options.foregroundColor = .white
      options.backgroundColor = .black
      self?.generateAndPreview(
        label: "compact.128",
        content: "FKKit compact QR",
        options: options
      )
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeGenerationOptions",
        description: "Nearest-neighbor scaling keeps modules sharp. Colors are applied via CIFalseColor before scaling.",
        body: body
      )
    )
    addClearLogButton()
  }
}
