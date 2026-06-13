import FKUIKit
import UIKit

final class FKQRCodeScannerExampleOverlayViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Overlay Style"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("Default overlay + animated scan line") { [weak self] in
      self?.presentScanner(label: "overlay.default")
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("Large frame · no scan line animation") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.overlayStyle = FKQRCodeOverlayStyle(
        scanRegionRelativeSize: 0.78,
        cornerLength: 28,
        cornerLineWidth: 5,
        showsScanLineAnimation: false
      )
      self?.presentScanner(label: "overlay.static", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeOverlayStyle",
        description: "Corner brackets and dimmed mask guide alignment. Scan line animation respects Reduce Motion.",
        body: body
      )
    )
    addClearLogButton()
  }
}
