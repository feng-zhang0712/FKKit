import FKUIKit
import UIKit

/// Shows makeButtonStateAppearances(for:) for all FKThemeButtonRole values.
final class FKThemeExampleButtonRolesViewController: FKThemeExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Button roles"

    let theme = FKThemeExampleSupport.makeBrandTheme()
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 12
    column.addArrangedSubview(FKThemeExampleSupport.makeThemedButton(title: "Primary", role: .primary, theme: theme))
    column.addArrangedSubview(FKThemeExampleSupport.makeThemedButton(title: "Secondary", role: .secondary, theme: theme))
    column.addArrangedSubview(FKThemeExampleSupport.makeThemedButton(title: "Destructive", role: .destructive, theme: theme))

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "FKThemeButtonRole",
        description: "Per-role appearances use metrics.radiusMedium corners and semantic fill/stroke colors.",
        content: column
      )
    )
  }
}
