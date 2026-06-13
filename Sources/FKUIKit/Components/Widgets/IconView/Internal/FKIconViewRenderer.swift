import FKCoreKit
import UIKit

enum FKIconViewRenderer {
  struct ResolvedContent {
    var image: UIImage?
    var renderingMode: UIImage.RenderingMode
    var isPlaceholder: Bool
  }

  static func resolve(
    symbolName: String?,
    image: UIImage?,
    configuration: FKIconViewConfiguration
  ) -> ResolvedContent {
    let appearance = configuration.appearance
    let layout = configuration.layout
    let pointSize = layout.size.symbolPointSize

    if let image {
      let target = CGSize(width: pointSize, height: pointSize)
      let scaled = image.fk_resized(to: target) ?? image
      if appearance.treatsCustomImageAsTemplate {
        return ResolvedContent(
          image: scaled.withRenderingMode(.alwaysTemplate),
          renderingMode: .alwaysTemplate,
          isPlaceholder: false
        )
      }
      return ResolvedContent(
        image: scaled.withRenderingMode(.alwaysOriginal),
        renderingMode: .alwaysOriginal,
        isPlaceholder: false
      )
    }

    if let symbolName, !symbolName.isEmpty {
      let symbolConfig = appearance.symbolConfiguration
        ?? UIImage.SymbolConfiguration(pointSize: pointSize, weight: appearance.symbolWeight)
      let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
      return ResolvedContent(
        image: symbol?.withRenderingMode(.alwaysTemplate),
        renderingMode: .alwaysTemplate,
        isPlaceholder: false
      )
    }

    switch layout.emptyContentBehavior {
    case .hidden:
      return ResolvedContent(image: nil, renderingMode: .alwaysTemplate, isPlaceholder: false)
    case .placeholder:
      let symbolConfig = appearance.symbolConfiguration
        ?? UIImage.SymbolConfiguration(pointSize: pointSize, weight: appearance.symbolWeight)
      let placeholder = UIImage(systemName: appearance.placeholderSymbolName, withConfiguration: symbolConfig)
      return ResolvedContent(
        image: placeholder?.withRenderingMode(.alwaysTemplate),
        renderingMode: .alwaysTemplate,
        isPlaceholder: true
      )
    }
  }

  static func backgroundColor(for style: FKIconViewBackgroundStyle) -> UIColor? {
    switch style {
    case .none:
      nil
    case .circle(let fill), .roundedRect(_, let fill):
      fill
    }
  }

  static func cornerRadius(for style: FKIconViewBackgroundStyle, side: CGFloat) -> CGFloat {
    switch style {
    case .none:
      0
    case .circle:
      side / 2
    case .roundedRect(let radius, _):
      radius
    }
  }
}

/// Shared renderer entry for ``FKWidgetIcon`` payloads (Chip, Tag, IconView).
enum FKIconViewWidgetIconRenderer {
  @MainActor
  static func apply(_ icon: FKWidgetIcon?, to view: FKIconView) {
    guard let icon else {
      view.symbolName = nil
      view.image = nil
      return
    }
    switch icon {
    case .symbol(let name, let config):
      view.symbolName = name
      view.image = nil
      if let config, let symbolConfig = config as? UIImage.SymbolConfiguration {
        var appearance = view.configuration.appearance
        appearance.symbolConfiguration = symbolConfig
        view.configuration.appearance = appearance
      }
    case .image(let image):
      view.image = image
      view.symbolName = nil
    }
  }
}
