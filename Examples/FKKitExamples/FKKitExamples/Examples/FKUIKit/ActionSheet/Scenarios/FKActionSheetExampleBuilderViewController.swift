import UIKit
import FKUIKit

final class FKActionSheetExampleBuilderViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Builder & Migration"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("FKActionSheetBuilder") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBuilder(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Alert migration") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentAlertMigration(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Migration helpers",
        description: "Fluent builder produces FKActionSheetConfiguration via build(); present with init(configuration:) + present(from:). Alert-style FKActionSheetConfiguration(alertTitle:...) for UIAlertAction migration.",
        body: body
      )
    )
    addClearLogButton()
  }
}
