#if canImport(SwiftUI)
  import FKCoreKit
  import SwiftUI

  /// Native SwiftUI workflow status pill mirroring ``FKStatusPill`` semantics.
  public struct FKStatusPillView: View {
    public var configuration: FKStatusPillConfiguration
    public var title: String
    public var style: FKStatusPillStyle
    public var showsDot: Bool

    public init(
      configuration: FKStatusPillConfiguration = FKStatusPillDefaults.configuration,
      title: String,
      style: FKStatusPillStyle = .neutral,
      showsDot: Bool = false
    ) {
      self.configuration = configuration
      self.title = title
      self.style = style
      self.showsDot = showsDot
    }

    public var body: some View {
      HStack(spacing: showsDot ? configuration.layout.dotSpacing : 0) {
        if showsDot {
          Circle()
            .fill(Color(palette.dot))
            .frame(width: configuration.layout.dotDiameter, height: configuration.layout.dotDiameter)
        }
        Text(title.fk_limitedPrefix(32))
          .font(Font(FKStatusPillRenderer.scaledTitleFont(configuration: configuration)))
          .lineLimit(1)
      }
      .padding(.horizontal, configuration.layout.horizontalPadding)
      .frame(height: configuration.layout.size.height)
      .background(Color(palette.background))
      .foregroundStyle(Color(palette.foreground))
      .clipShape(Capsule())
      .accessibilityLabel(Text(accessibilityText))
    }

    private var palette: FKStatusPillRenderer.Colors {
      FKStatusPillRenderer.colors(
        for: style,
        dotColorOverride: configuration.appearance.dotColorOverride
      )
    }

    private var accessibilityText: String {
      if let custom = configuration.accessibility.customLabel {
        return custom
      }
      if configuration.accessibility.includesStatusSuffix {
        return FKStatusPillI18n.accessibilityLabel(title: title)
      }
      return title
    }
  }
#endif
