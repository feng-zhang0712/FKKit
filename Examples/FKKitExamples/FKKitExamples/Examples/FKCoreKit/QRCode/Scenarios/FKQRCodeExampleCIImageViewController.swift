import CoreImage
import FKCoreKit
import UIKit

final class FKQRCodeExampleCIImageViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CIImage Output"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("makeCIImage → CGImage preview") { [weak self] in
      self?.renderCIImagePath()
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeGenerator.makeCIImage",
        description: "Returns a scaled CIImage suitable for Core Image pipelines. Convert to UIImage when you need UIKit display.",
        body: body
      )
    )
    addClearLogButton()
    renderCIImagePath()
  }

  private func renderCIImagePath() {
    do {
      var options = FKQRCodeGenerationOptions.default
      options.size = CGSize(width: 240, height: 240)
      let ciImage = try FKQRCodeGenerator.makeCIImage(
        from: "https://example.com/ciimage",
        options: options
      )
      let context = CIContext(options: nil)
      guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        log("ciimage: imageConversionFailed")
        showPreview(nil)
        return
      }
      showPreview(UIImage(cgImage: cgImage, scale: 1, orientation: .up))
      log("ciimage: extent=\(Int(ciImage.extent.width))×\(Int(ciImage.extent.height))")
    } catch let error as FKQRCodeError {
      showPreview(nil)
      log("ciimage: \(FKQRCodeExampleFormatting.describe(error))")
    } catch {
      showPreview(nil)
      log("ciimage: \(error.localizedDescription)")
    }
  }
}
