import FKUIKit
import UIKit

/// Classic transparent → solid navigation chrome over a hero.
final class FKNavigationBarScrollTransparentSolidExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Transparent → Solid" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Hero"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      systemItem: .action,
      primaryAction: UIAction { _ in }
    )

    addIntro(
      title: "Transparent → solid",
      body: "Uses scrollView.fk_navigationBarScrollEngine with .transparent / .solid factories, bind(viewController:), automatic KVO, and navigationItem appearance writes."
    )
    addFillerBlocks()

    _ = installDefaultEngine()
  }
}
