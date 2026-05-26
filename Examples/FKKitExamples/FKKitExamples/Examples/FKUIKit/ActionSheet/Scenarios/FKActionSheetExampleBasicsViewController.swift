import UIKit
import FKUIKit

final class FKActionSheetExampleBasicsViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Instance API (recommended)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentInstanceAPI(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Standard sheet") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentBasics(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Validate empty config") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentValidationFailure(from: self)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "FKActionSheet view controller",
        description: "FKActionSheet is a UIViewController. Create with init(configuration:), call present(from:), and retain the instance for reload or dismiss.",
        body: body
      )
    )
    addClearLogButton()
  }
}
