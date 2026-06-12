import FKUIKit
import UIKit

final class FKQRCodeScannerExampleNavigationPolicyViewController: FKQRCodeScannerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigation Policy"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKQRCodeExampleUI.button("callbackOnly (safest default)") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.navigationPolicy = .callbackOnly
      config.simulatorMockRawValue = "https://example.com/policy-demo"
      self?.presentScanner(label: "policy.callbackOnly", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("openHTTPInApp — SFSafariViewController") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.navigationPolicy = .openHTTPInApp
      config.simulatorMockRawValue = "https://example.com/policy-demo"
      self?.presentScanner(label: "policy.inApp", configuration: config)
    })
    body.addArrangedSubview(FKQRCodeExampleUI.button("openExternally — UIApplication.shared.open") { [weak self] in
      var config = FKQRCodeScannerConfiguration.default
      config.navigationPolicy = .openExternally
      config.simulatorMockRawValue = "https://example.com/policy-demo"
      self?.presentScanner(label: "policy.external", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeNavigationPolicy",
        description: "Delegate always receives the payload first. Automatic URL open is opt-in; validate untrusted codes in production.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("On Simulator use Mock scanner → Simulate Scan to trigger the mock HTTPS URL.")
    )
    addClearLogButton()
  }
}
