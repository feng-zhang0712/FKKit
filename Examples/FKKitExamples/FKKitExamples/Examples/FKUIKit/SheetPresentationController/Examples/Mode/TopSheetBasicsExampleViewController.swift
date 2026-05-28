import UIKit
import FKUIKit

/// Presents a top-attached sheet, mirroring a “drop-down tray” interaction.
///
/// Key highlights:
/// - Uses `.topSheet` mode.
/// - Includes both `.large` (near-full) and `.full` (true full-screen).
/// - Good for transient top menus, banners with actions, or filter trays.
/// Caveat:
/// - Consider safe area when presenting under the notch/status bar.
final class TopSheetBasicsExampleViewController: FKSheetPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Top sheet — Basics",
      subtitle: "A sheet attached to the top edge, expanding downward.",
      notes: "Tip: top sheets often pair well with an anchor (under navigation bar) when you want a precise attachment line."
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.topSheetConfiguration()
      configuration.sheet.detents = [.fitContent, .medium, .large, .full]
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "Top sheet", configuration: configuration)
    }
  }
}

