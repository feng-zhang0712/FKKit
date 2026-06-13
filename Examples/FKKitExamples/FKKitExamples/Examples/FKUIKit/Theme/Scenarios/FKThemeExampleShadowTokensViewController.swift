import FKUIKit
import UIKit

/// Renders FKThemeShadowTokens elevations on sample cards.
final class FKThemeExampleShadowTokensViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Shadow elevations"

    let theme = FKThemeRegistry.current
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.distribution = .fillEqually

    let elevations: [(String, FKLayerShadowStyle)] = [
      ("Low", theme.shadows.elevationLow),
      ("Medium", theme.shadows.elevationMedium),
      ("High", theme.shadows.elevationHigh),
    ]

    elevations.forEach { title, style in
      row.addArrangedSubview(shadowCard(title: title, style: style))
    }

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKLayerShadowStyle presets",
        description: "Theme shadow tokens map directly to CALayer shadow parameters via fk_applyShadow.",
        content: row
      )
    )
  }

  private func shadowCard(title: String, style: FKLayerShadowStyle) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8
    wrap.alignment = .center

    let surface = UIView()
    surface.backgroundColor = FKThemeRegistry.current.colors.surface.resolved(for: traitCollection)
    surface.layer.cornerRadius = FKThemeRegistry.current.metrics.radiusMedium
    surface.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      surface.widthAnchor.constraint(equalToConstant: 88),
      surface.heightAnchor.constraint(equalToConstant: 88),
    ])
    FKThemeExampleSupport.applyLayerShadow(style, to: surface.layer)

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .caption1)
    wrap.addArrangedSubview(surface)
    wrap.addArrangedSubview(label)
    return wrap
  }
}
