import UIKit
import FKUIKit

/// Uses fixed-point detents and demonstrates programmatic detent switching.
///
/// Key highlights:
/// - Two fixed detents (`.fixed(240)`, `.fixed(520)`).
/// - Uses `FKSheetPresentationController.selectDetent(_:animated:)` from outside the presented controller.
final class SheetDetentsPointsExampleViewController: FKSheetPresentationExamplePageViewController {
  private var currentController: FKSheetPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Detents — Points",
      subtitle: "Two fixed heights plus buttons to switch detents programmatically.",
      notes: "Programmatic detent switching is useful for guided flows (e.g. expanding after validation)."
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(240), .fixed(520)]
      configuration.sheet.initialSelectedDetentIndex = 0
      self.currentController = FKSheetPresentationExampleHelpers.present(from: self, title: "Points detents", configuration: configuration)
    }

    addPrimaryButton(title: "Switch to 240pt") { [weak self] in
      self?.currentController?.selectDetent(.fixed(240), animated: true)
    }

    addPrimaryButton(title: "Switch to 520pt") { [weak self] in
      self?.currentController?.selectDetent(.fixed(520), animated: true)
    }
  }
}

