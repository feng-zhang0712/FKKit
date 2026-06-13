import FKCoreKit
import UIKit

final class FKQRCodeExampleParserViewController: FKQRCodeExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Parser Payloads"

    let samples: [(String, String)] = [
      ("HTTPS URL", "https://example.com/checkout?sku=42"),
      ("HTTP URL", "http://example.com/legacy"),
      ("Custom scheme", "myapp://product/123"),
      ("Plain text", "WIFI:S:Guest;T:WPA;P:secret;;"),
      ("Unknown empty", "   "),
    ]

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    for (title, raw) in samples {
      body.addArrangedSubview(FKQRCodeExampleUI.button(title) { [weak self] in
        let payload = FKQRCodeParser.parse(raw)
        self?.log("parse(\(title)): \(FKQRCodeExampleFormatting.describe(payload))")
        self?.log("  rawValue → \(payload.rawValue)")
      })
    }

    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.section(
        title: "FKQRCodeParser.parse",
        description: "Scanner metadata strings are parsed into FKQRCodePayload before delegate callbacks.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKQRCodeExampleUI.caption("Wi-Fi WIFI:… strings are classified as .text in v1; dedicated .wifi case is reserved for a future release.")
    )
    addClearLogButton()
  }
}
