import FKCoreKit
import UIKit

final class FKQRCodeExampleLogoEmbeddingViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Logo Embedding"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Center logo · correction auto-upgrades to H") { [weak self] in
      guard let self else { return }
      let logo = Self.makeDemoLogo()
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 280, height: 280)
      options.correctionLevel = .M
      options.logo = FKQRCodeLogoEmbedding(
        image: logo,
        maxRelativeSize: 0.22,
        cornerRadius: 8
      )
      self.generateAndPreview(
        label: "logo.center",
        content: "https://example.com/logo-demo",
        options: options
      )
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Without logo (same URL, M correction)") { [weak self] in
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 280, height: 280)
      options.correctionLevel = .M
      self?.generateAndPreview(
        label: "logo.none",
        content: "https://example.com/logo-demo",
        options: options
      )
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeLogoEmbedding",
        description: "Logo area is clamped to 22% of the QR side. Verify scannability on a device after embedding.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Logo is composited in UIKit after CIImage generation; makeCIImage does not embed logos.")
    )
    addClearLogButton()
  }

  private static func makeDemoLogo() -> UIImage {
    let size = CGSize(width: 64, height: 64)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      UIColor.systemIndigo.setFill()
      context.fill(CGRect(origin: .zero, size: size))
      let symbol = UIImage(systemName: "qrcode")?
        .withTintColor(.white, renderingMode: .alwaysOriginal)
      symbol?.draw(in: CGRect(x: 16, y: 16, width: 32, height: 32))
    }
  }
}
