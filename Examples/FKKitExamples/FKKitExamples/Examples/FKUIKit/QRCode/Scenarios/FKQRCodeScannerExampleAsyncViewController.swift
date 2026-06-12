import FKUIKit
import UIKit

final class FKQRCodeScannerExampleAsyncViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Async Scan"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("await scan(from:)") { [weak self] in
      self?.runAsyncScan()
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("await scan — continuous mode") { [weak self] in
      self?.runAsyncScan(continuous: true)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeScannerViewController.scan(from:)",
        description: "Wraps delegate + continuation. Cancellation maps to CancellationError; dismiss the scanner with the close button to cancel.",
        body: body
      )
    )
    addClearLogButton()
  }

  private func runAsyncScan(continuous: Bool = false) {
    log("async: presenting…")
    Task { @MainActor [weak self] in
      guard let self else { return }
      var config = FKQRCodeScannerConfiguration.default
      config.scanMode = continuous ? .continuous : .once
      do {
        let payload = try await FKQRCodeScannerViewController.scan(from: self, configuration: config)
        self.log("async: success → \(FKQRCodeExampleFormatting.describe(payload))")
        self.presentMessageAlert(
          title: "Scan Result",
          message: FKQRCodeExampleFormatting.describe(payload)
        )
      } catch is CancellationError {
        self.log("async: cancelled")
      } catch let error as FKQRCodeScannerError {
        self.log("async: \(FKQRCodeScannerExampleFormatting.describe(error))")
      } catch {
        self.log("async: \(error.localizedDescription)")
      }
    }
  }
}
