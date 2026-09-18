import FKUIKit
import UIKit

/// Emphasizes titleAlpha fade while other chrome interpolates.
final class FKNavigationBarScrollTitleFadeExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Title Fade" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Album"

    addIntro(
      title: "Title fade-in",
      body: "from.titleAlpha = 0 and to.titleAlpha = 1. Scroll until the title becomes readable on the solid bar."
    )
    addFillerBlocks()

    _ = installDefaultEngine { engine in
      engine.fromAppearance = .transparent(
        tint: .white,
        titleColor: .white,
        titleAlpha: 0,
        statusBarStyle: .lightContent
      )
      engine.toAppearance = .solid(
        backgroundColor: .systemBackground,
        titleColor: .label,
        tintColor: .label,
        titleAlpha: 1,
        shadowAlpha: 1,
        statusBarStyle: .darkContent
      )
    }
  }
}
