import FKUIKit
import UIKit

/// Writes appearances on UINavigationBar instead of navigationItem.
final class FKNavigationBarScrollApplyNavigationBarExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Bar Target" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Nav Bar"

    addIntro(
      title: "applicationTarget = .navigationBar",
      body: "Automatic apply writes standard/scrollEdge/compact appearances on navigationController.navigationBar. Prefer .navigationItem for push stacks; this demo shows the bar-wide path."
    )
    addFillerBlocks()

    _ = installDefaultEngine { engine in
      var configuration = engine.configuration
      configuration.applicationTarget = .navigationBar
      engine.configuration = configuration
    }
  }
}
