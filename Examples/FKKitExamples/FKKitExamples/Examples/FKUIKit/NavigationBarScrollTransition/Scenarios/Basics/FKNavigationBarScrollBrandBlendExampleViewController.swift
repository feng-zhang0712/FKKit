import FKUIKit
import UIKit

/// Custom color endpoints instead of clear → systemBackground only.
final class FKNavigationBarScrollBrandBlendExampleViewController:
  FKNavigationBarScrollExampleHeroPageViewController
{
  override var heroTitle: String { "Brand Blend" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Brand"

    addIntro(
      title: "Brand color blend",
      body: "Custom FKNavigationBarScrollAppearance endpoints: clear indigo tint → opaque systemBackground with shadowAlpha ramp."
    )
    addFillerBlocks()

    _ = installDefaultEngine { engine in
      // Start fully clear so the hero shows through; indigo participates once alpha rises.
      engine.fromAppearance = FKNavigationBarScrollAppearance(
        backgroundColor: .systemIndigo,
        backgroundAlpha: 0,
        titleColor: .white,
        titleAlpha: 0,
        tintColor: .white,
        shadowAlpha: 0,
        statusBarStyle: .lightContent
      )
      engine.toAppearance = FKNavigationBarScrollAppearance(
        backgroundColor: .systemBackground,
        backgroundAlpha: 1,
        titleColor: .label,
        titleAlpha: 1,
        tintColor: .systemIndigo,
        shadowAlpha: 1,
        statusBarStyle: .darkContent
      )
    }
  }
}
