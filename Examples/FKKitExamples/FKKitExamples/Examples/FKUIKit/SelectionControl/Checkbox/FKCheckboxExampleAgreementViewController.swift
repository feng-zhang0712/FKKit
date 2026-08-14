import FKUIKit
import UIKit

/// checkbox.agreement — rich text links + required.
final class FKCheckboxExampleAgreementViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Agreement"

    var attributed = AttributedString("I agree to the ")
    var terms = AttributedString("Terms of Service")
    terms.link = URL(string: "https://example.com/terms")
    attributed.append(terms)
    attributed.append(AttributedString(" and "))
    var privacy = AttributedString("Privacy Policy")
    privacy.link = URL(string: "https://example.com/privacy")
    attributed.append(privacy)
    attributed.append(AttributedString("."))

    let checkbox = FKCheckbox(
      configuration: FKCheckboxPresets.agreement(),
      content: FKCheckboxContentConfiguration(attributedTitle: attributed, isRequired: true)
    )
    let (status, updateStatus) = FKSelectionExampleSupport.statusLabel(prefix: "Link")
    checkbox.onLinkActivated = { url in
      updateStatus(url.absoluteString)
    }
    checkbox.onStateChanged = { state in
      if state == .checked { updateStatus("accepted") }
    }

    let box = FKSelectionExampleSupport.sectionContainer(title: "Terms of Service")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Link taps fire onLinkActivated and do not toggle by default. Required appends a red asterisk."))
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    box.addArrangedSubview(status)
    contentStack.addArrangedSubview(box)
  }
}
