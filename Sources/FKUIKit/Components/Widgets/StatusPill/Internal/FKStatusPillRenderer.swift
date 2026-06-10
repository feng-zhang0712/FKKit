import UIKit

enum FKStatusPillRenderer {
  struct Colors {
    var background: UIColor
    var foreground: UIColor
    var dot: UIColor
  }

  static func colors(
    for style: FKStatusPillStyle,
    dotColorOverride: UIColor?
  ) -> Colors {
    switch style {
    case .custom(let custom):
      return Colors(
        background: custom.backgroundColor,
        foreground: custom.foregroundColor,
        dot: dotColorOverride ?? custom.dotColor ?? custom.foregroundColor
      )
    default:
      let semantic = style.semantic ?? .neutral
      let palette = FKWidgetStatusColorTokens.palette(for: semantic)
      return Colors(
        background: palette.background,
        foreground: palette.foreground,
        dot: dotColorOverride ?? palette.foreground
      )
    }
  }

  @MainActor
  static func scaledTitleFont(
    configuration: FKStatusPillConfiguration
  ) -> UIFont {
    let appearance = configuration.appearance
    let height = configuration.layout.size.height
    let metrics = UIFontMetrics(forTextStyle: appearance.textStyle)
    let reference = UIFont.preferredFont(forTextStyle: appearance.textStyle)
    let defaultCap = reference.pointSize + 2
    let maximumPointSize = appearance.maximumTitlePointSize ?? defaultCap
    let heightScale = height / FKStatusPillSize.s.height
    let baseSize = max(11, appearance.titleFont.pointSize * heightScale)
    let base = appearance.titleFont.withSize(baseSize)
    return metrics.scaledFont(for: base, maximumPointSize: maximumPointSize)
  }

  static func shouldPulseDot(style: FKStatusPillStyle, configuration: FKStatusPillConfiguration) -> Bool {
    configuration.appearance.pulsesDotForInfoStyle && style == .info
  }
}
