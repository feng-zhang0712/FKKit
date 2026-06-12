import FKUIKit
import UIKit

/// Displays every FKThemeColorRole using FKThemeResolver.
final class FKThemeExampleColorPaletteViewController: FKThemeExampleBaseViewController {

  private var paletteCard: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Color palette"
    rebuildPalette()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    rebuildPalette()
  }

  private func rebuildPalette() {
    paletteCard?.removeFromSuperview()

    let theme = FKThemeRegistry.current
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10

    FKThemeColorRole.allCases.forEach { role in
      let color = FKThemeResolver.color(role, in: theme, traitCollection: traitCollection)
      column.addArrangedSubview(FKThemeExampleSupport.colorSwatch(name: String(describing: role), color: color))
    }

    let card = FKThemeExampleSupport.card(
      title: "Semantic roles",
      description: "Colors resolve for the current UITraitCollection (toggle light/dark in Control Center to preview).",
      content: column
    )
    paletteCard = card
    stack.addArrangedSubview(card)

    if stack.arrangedSubviews.count == 1 {
      stack.addArrangedSubview(
        FKThemeExampleSupport.bodyLabel("FKThemeColor supports light/dark pairs via resolved(for:) and uiColor() dynamic providers.")
      )
    }
  }
}
