import FKUIKit
import UIKit

/// Writes appearances to both navigationItem and navigationBar.
final class FKNavigationBarScrollApplyBothExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Both Targets" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Both"

    addIntro(
      title: "applicationTarget = .both",
      body: "Applies to navigationItem first, then the shared UINavigationBar (including tintColor)."
    )
    addFillerBlocks()

    _ = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.applicationTarget = .both
      engine.configuration = configuration
    }
  }
}
