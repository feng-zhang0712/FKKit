import UIKit

enum FKRatingIconResolver {
  static func emptyImage(for appearance: FKRatingAppearanceConfiguration) -> UIImage? {
    resolvedImage(kind: .empty, appearance: appearance)
  }

  static func filledImage(for appearance: FKRatingAppearanceConfiguration) -> UIImage? {
    resolvedImage(kind: .filled, appearance: appearance)
  }

  private enum Kind {
    case empty
    case filled
    case half
  }

  private static func resolvedImage(
    kind: Kind,
    appearance: FKRatingAppearanceConfiguration
  ) -> UIImage? {
    let base: UIImage?
    switch appearance.iconStyle {
    case let .preset(preset):
      base = presetImage(preset: preset, kind: kind, symbolConfiguration: appearance.symbolConfiguration)
    case let .symbols(empty, filled, half):
      let name: String
      switch kind {
      case .empty:
        name = empty
      case .filled:
        name = filled
      case .half:
        name = half ?? filled
      }
      base = symbolImage(named: name, configuration: appearance.symbolConfiguration)
    case let .images(empty, filled, half):
      switch kind {
      case .empty:
        base = empty
      case .filled:
        base = filled
      case .half:
        base = half ?? filled
      }
    }

    guard let base else { return nil }
    return base.withRenderingMode(appearance.renderingMode)
  }

  private static func presetImage(
    preset: FKRatingIconPreset,
    kind: Kind,
    symbolConfiguration: UIImage.SymbolConfiguration?
  ) -> UIImage? {
    let name: String
    switch preset {
    case .star:
      switch kind {
      case .empty:
        name = "star"
      case .filled:
        name = "star.fill"
      case .half:
        name = "star.leadinghalf.filled"
      }
    case .heart:
      switch kind {
      case .empty:
        name = "heart"
      case .filled:
        name = "heart.fill"
      case .half:
        name = "heart.leadinghalf.filled"
      }
    case .thumbUp:
      switch kind {
      case .empty:
        name = "hand.thumbsup"
      case .filled:
        name = "hand.thumbsup.fill"
      case .half:
        name = "hand.thumbsup.fill"
      }
    }
    return symbolImage(named: name, configuration: symbolConfiguration)
  }

  private static func symbolImage(
    named name: String,
    configuration: UIImage.SymbolConfiguration?
  ) -> UIImage? {
    if let configuration {
      return UIImage(systemName: name, withConfiguration: configuration)
    }
    return UIImage(systemName: name)
  }
}
