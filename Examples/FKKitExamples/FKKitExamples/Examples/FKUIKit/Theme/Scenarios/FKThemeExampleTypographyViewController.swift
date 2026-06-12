import FKUIKit
import UIKit

/// Shows the full FKThemeTextStyle ramp with Dynamic Type scaling.
final class FKThemeExampleTypographyViewController: FKThemeExampleBaseViewController {

  private let contentSizeControl = UISegmentedControl(items: ["Large", "AX1", "AX2", "AX3"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Typography"

    contentSizeControl.selectedSegmentIndex = 0
    contentSizeControl.addAction(UIAction { [weak self] _ in self?.rebuildSamples() }, for: .valueChanged)
    stack.addArrangedSubview(contentSizeControl)
    rebuildSamples()
  }

  private func rebuildSamples() {
    stack.arrangedSubviews.dropFirst().forEach { $0.removeFromSuperview() }

    let category = contentSizeCategory(for: contentSizeControl.selectedSegmentIndex)
    let theme = FKThemeRegistry.current
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 12

    FKThemeTextStyle.allCases.forEach { style in
      let font = theme.typography.font(for: style, contentSizeCategory: category)
      let metrics = theme.typography.scaledMetrics(for: style, baseValue: 24, contentSizeCategory: category)
      let label = UILabel()
      label.numberOfLines = 0
      label.font = font
      label.text = "\(style) — \(Int(font.pointSize)) pt (scaled metric \(Int(metrics.scaledValue)))"
      column.addArrangedSubview(label)
    }

    stack.addArrangedSubview(
      FKThemeExampleSupport.card(
        title: "Text ramp",
        description: "UIFontMetrics scales base fonts per FKThemeTextStyle. Adjust the segment to preview accessibility sizes.",
        content: column
      )
    )
  }

  private func contentSizeCategory(for index: Int) -> UIContentSizeCategory {
    switch index {
    case 1: return .accessibilityExtraLarge
    case 2: return .accessibilityExtraExtraLarge
    case 3: return .accessibilityExtraExtraExtraLarge
    default: return .large
    }
  }
}
