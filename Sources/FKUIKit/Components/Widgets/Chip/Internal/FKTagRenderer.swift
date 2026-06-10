import UIKit

enum FKTagRenderer {
  struct Colors {
    var background: UIColor
    var foreground: UIColor
    var border: UIColor?
    var borderWidth: CGFloat
  }

  static func colors(for variant: FKTagVariant, tintColor: UIColor) -> Colors {
    switch variant {
    case .neutral:
      Colors(background: .secondarySystemFill, foreground: .secondaryLabel, border: nil, borderWidth: 0)
    case .brand:
      Colors(background: tintColor.withAlphaComponent(0.15), foreground: tintColor, border: nil, borderWidth: 0)
    case .success:
      Colors(background: UIColor.systemGreen.withAlphaComponent(0.15), foreground: .systemGreen, border: nil, borderWidth: 0)
    case .warning:
      Colors(background: UIColor.systemOrange.withAlphaComponent(0.15), foreground: .systemOrange, border: nil, borderWidth: 0)
    case .error:
      Colors(background: UIColor.systemRed.withAlphaComponent(0.15), foreground: .systemRed, border: nil, borderWidth: 0)
    case .outline:
      Colors(background: .clear, foreground: .label, border: .separator, borderWidth: 1)
    case .custom(let custom):
      Colors(
        background: custom.backgroundColor,
        foreground: custom.foregroundColor,
        border: custom.borderColor,
        borderWidth: custom.borderWidth
      )
    }
  }

  @MainActor
  static func scaledFont(base: UIFont, size: FKChipSize) -> UIFont {
    let scale = size.height / 30
    let metrics = UIFontMetrics(forTextStyle: .caption1)
    let scaled = metrics.scaledFont(for: base)
    return scaled.withSize(max(11, scaled.pointSize * scale))
  }
}
