import UIKit
import FKUIKit

final class FKActionSheetExampleBasicsViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Standard sheet") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentBasics(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Convenience API") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentConvenienceAPI(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Validate empty config") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentValidationFailure(from: self)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Standard presentation",
        description: "Title/message header, default + destructive actions, separated cancel row, and throws-based present API.",
        body: body
      )
    )
    addClearLogButton()
  }
}
