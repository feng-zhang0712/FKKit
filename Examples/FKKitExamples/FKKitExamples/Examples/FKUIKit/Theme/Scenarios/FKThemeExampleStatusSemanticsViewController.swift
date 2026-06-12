import FKUIKit
import UIKit

/// Compares theme status colors with FKStatusPill workflow semantics.
final class FKThemeExampleStatusSemanticsViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Status semantics"

    let theme = FKThemeRegistry.current
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10

    let mapping: [(FKWidgetStatusSemantic, String)] = [
      (.success, "Delivered"),
      (.warning, "Pending"),
      (.error, "Failed"),
      (.info, "Processing"),
      (.neutral, "Draft"),
    ]

    mapping.forEach { semantic, title in
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 12
      row.alignment = .center

      let pill = FKStatusPill()
      pill.title = title
      pill.style = pillStyle(for: semantic)

      let swatch = FKThemeExampleSupport.colorSwatch(
        name: String(describing: semantic),
        color: FKThemeResolver.statusColor(for: semantic, in: theme, traitCollection: traitCollection)
      )

      row.addArrangedSubview(pill)
      row.addArrangedSubview(swatch)
      column.addArrangedSubview(row)
    }

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKWidgetStatusSemantic",
        description: "Theme status tokens delegate to FKWidgetStatusColorTokens in the default factory while FKStatusPill renders workflow UI.",
        content: column
      )
    )
  }

  private func pillStyle(for semantic: FKWidgetStatusSemantic) -> FKStatusPillStyle {
    switch semantic {
    case .success: .success
    case .warning: .warning
    case .error: .error
    case .info: .info
    case .neutral: .neutral
    }
  }
}
