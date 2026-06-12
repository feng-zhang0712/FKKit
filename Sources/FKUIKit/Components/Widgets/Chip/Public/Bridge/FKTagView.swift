#if canImport(SwiftUI)
  import FKCoreKit
  import SwiftUI

  /// Native SwiftUI read-only tag mirroring ``FKTag`` semantics.
  public struct FKTagView: View {
    public var configuration: FKTagConfiguration
    public var title: String
    public var variant: FKTagVariant
    public var leadingIcon: FKTagIcon?

    public init(
      configuration: FKTagConfiguration = FKTagDefaults.configuration,
      title: String,
      variant: FKTagVariant = .neutral,
      leadingIcon: FKTagIcon? = nil
    ) {
      self.configuration = configuration
      self.title = title
      self.variant = variant
      self.leadingIcon = leadingIcon
    }

    public var body: some View {
      HStack(spacing: configuration.layout.iconSpacing) {
        if let leadingIcon {
          iconView(leadingIcon)
        }
        Text(title.fk_limitedPrefix(48))
          .font(.system(size: scaledFont().pointSize, weight: .semibold))
          .lineLimit(1)
      }
      .padding(.horizontal, configuration.layout.horizontalPadding)
      .frame(height: configuration.layout.size.height)
      .background(backgroundColor)
      .foregroundStyle(foregroundColor)
      .overlay {
        if borderWidth > 0 {
          Capsule().strokeBorder(borderColor, lineWidth: borderWidth)
        }
      }
      .clipShape(Capsule())
      .accessibilityLabel(Text(configuration.accessibility.customLabel ?? title))
    }

    private var palette: FKTagRenderer.Colors {
      FKTagRenderer.colors(for: variant, tintColor: UIColor(Color.accentColor))
    }

    private var backgroundColor: Color {
      Color(palette.background)
    }

    private var foregroundColor: Color {
      Color(palette.foreground)
    }

    private var borderColor: Color {
      Color(palette.border ?? .separator)
    }

    private var borderWidth: CGFloat {
      palette.borderWidth
    }

    private func scaledFont() -> UIFont {
      FKTagRenderer.scaledFont(base: configuration.appearance.titleFont, size: configuration.layout.size)
    }

    @ViewBuilder
    private func iconView(_ icon: FKTagIcon) -> some View {
      if let image = icon.resolvedTemplateImage(
        pointSize: configuration.layout.size.height * 0.4
      ) {
        Image(uiImage: image)
          .renderingMode(.template)
      }
    }
  }
#endif
