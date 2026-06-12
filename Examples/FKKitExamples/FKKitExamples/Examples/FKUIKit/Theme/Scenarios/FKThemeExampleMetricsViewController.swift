import FKUIKit
import UIKit

/// Visualizes FKThemeMetrics spacing, radii, and hit-target constants.
final class FKThemeExampleMetricsViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Metrics"

    let metrics = FKThemeRegistry.current.metrics
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 12

    let spacingTokens: [(FKThemeSpacingToken, String)] = [
      (.xxs, "xxs"), (.xs, "xs"), (.s, "s"), (.m, "m"), (.l, "l"), (.xl, "xl"),
    ]
    spacingTokens.forEach { token, name in
      column.addArrangedSubview(spacingRow(name: name, value: metrics.spacing(token)))
    }

    column.addArrangedSubview(metricLabel("radiusSmall", metrics.radiusSmall))
    column.addArrangedSubview(metricLabel("radiusMedium", metrics.radiusMedium))
    column.addArrangedSubview(metricLabel("radiusLarge", metrics.radiusLarge))
    column.addArrangedSubview(metricLabel("minimumHitTarget", metrics.minimumHitTarget))
    column.addArrangedSubview(metricLabel("hairline", metrics.hairline))

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKThemeMetrics",
        description: "Spacing bars visualize token width; corner radii apply to the sample chips below.",
        content: column
      )
    )

    let radiiRow = UIStackView()
    radiiRow.axis = .horizontal
    radiiRow.spacing = 12
    radiiRow.distribution = .fillEqually
    [metrics.radiusSmall, metrics.radiusMedium, metrics.radiusLarge].forEach { radius in
      let chip = UIView()
      chip.backgroundColor = FKThemeRegistry.current.colors.secondary.resolved(for: traitCollection)
      chip.layer.cornerRadius = radius
      chip.translatesAutoresizingMaskIntoConstraints = false
      chip.heightAnchor.constraint(equalToConstant: 56).isActive = true
      radiiRow.addArrangedSubview(chip)
    }
    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Corner radii",
        description: "Small / medium / large radius tokens on equal-width chips.",
        content: radiiRow
      )
    )
  }

  private func spacingRow(name: String, value: CGFloat) -> UIView {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.alignment = .center
    let bar = UIView()
    bar.backgroundColor = FKThemeRegistry.current.colors.primary.resolved(for: traitCollection)
    bar.layer.cornerRadius = 4
    bar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bar.widthAnchor.constraint(equalToConstant: value),
      bar.heightAnchor.constraint(equalToConstant: 16),
    ])
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.text = "\(name): \(Int(value)) pt"
    row.addArrangedSubview(bar)
    row.addArrangedSubview(label)
    return row
  }

  private func metricLabel(_ name: String, _ value: CGFloat) -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    label.text = "\(name): \(value)"
    return label
  }
}
