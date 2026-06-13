import FKUIKit
import UIKit

/// Compares FKTheme.default and FKTheme.defaultDark snapshots.
final class FKThemeExampleBuiltInPresetsViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Built-in presets"

    stack.addArrangedSubview(presetCard(title: "FKTheme.default", theme: .default))
    stack.addArrangedSubview(presetCard(title: "FKTheme.defaultDark", theme: .defaultDark))

    stack.addArrangedSubview(
      FKThemeExampleSupport.bodyLabel(
        "Both presets use adaptive system semantic colors. Register either built-in snapshot to restore factory component defaults via FKThemeComponentIntegration."
      )
    )
  }

  private func presetCard(title: String, theme: FKTheme) -> UIView {
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 8

    let idLabel = UILabel()
    idLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    idLabel.text = "id: \(theme.id)"

    column.addArrangedSubview(idLabel)
    column.addArrangedSubview(
      FKThemeExampleSupport.colorSwatch(
        name: "primary",
        color: theme.colors.primary.resolved(for: traitCollection)
      )
    )
    column.addArrangedSubview(
      FKThemeExampleSupport.colorSwatch(
        name: "surface",
        color: theme.colors.surface.resolved(for: traitCollection)
      )
    )

    return FKThemeExampleSupport.card(
      title: title,
      description: "Immutable Sendable snapshot — copy and mutate before register.",
      content: column
    )
  }
}
