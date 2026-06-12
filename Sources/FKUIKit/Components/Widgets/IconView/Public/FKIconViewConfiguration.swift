import UIKit

/// Fixed square container sizes for ``FKIconView``.
public enum FKIconViewSize: Sendable, Equatable {
  /// 24×24 pt — list rows, compact chips.
  case s
  /// 28×28 pt — settings rows, default leading icon.
  case m
  /// 32×32 pt — emphasized leading icons.
  case l

  /// Container side length in points.
  public var side: CGFloat {
    switch self {
    case .s: 24
    case .m: 28
    case .l: 32
    }
  }

  /// Recommended SF Symbol point size for this container tier.
  public var symbolPointSize: CGFloat {
    switch self {
    case .s: 13
    case .m: 15
    case .l: 17
    }
  }
}

/// Background chrome behind the glyph in ``FKIconView``.
public enum FKIconViewBackgroundStyle: Sendable, Equatable {
  /// Transparent background (glyph only).
  case none
  /// Circular fill behind the icon.
  case circle(fill: UIColor)
  /// Rounded rectangle fill (settings-row style).
  case roundedRect(cornerRadius: CGFloat, fill: UIColor)
}

/// Behavior when both ``FKIconView/symbolName`` and ``FKIconView/image`` are empty.
public enum FKIconViewEmptyContentBehavior: Sendable, Equatable {
  /// Collapse the glyph (background may still show).
  case hidden
  /// Show a placeholder SF Symbol.
  case placeholder
}

/// Layout parameters for ``FKIconView``.
public struct FKIconViewLayoutConfiguration: Sendable, Equatable {
  public var size: FKIconViewSize
  public var emptyContentBehavior: FKIconViewEmptyContentBehavior

  public init(
    size: FKIconViewSize = .m,
    emptyContentBehavior: FKIconViewEmptyContentBehavior = .hidden
  ) {
    self.size = size
    self.emptyContentBehavior = emptyContentBehavior
  }
}

/// Visual styling for ``FKIconView``.
public struct FKIconViewAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var backgroundStyle: FKIconViewBackgroundStyle
  public var defaultTintColor: UIColor
  public var symbolConfiguration: UIImage.SymbolConfiguration?
  public var symbolWeight: UIImage.SymbolWeight
  /// When `true`, custom ``FKIconView/image`` values are template-tinted; otherwise aspect-fit original rendering is used.
  public var treatsCustomImageAsTemplate: Bool
  public var placeholderSymbolName: String

  public init(
    backgroundStyle: FKIconViewBackgroundStyle = .none,
    defaultTintColor: UIColor = .label,
    symbolConfiguration: UIImage.SymbolConfiguration? = nil,
    symbolWeight: UIImage.SymbolWeight = .medium,
    treatsCustomImageAsTemplate: Bool = false,
    placeholderSymbolName: String = "questionmark.circle"
  ) {
    self.backgroundStyle = backgroundStyle
    self.defaultTintColor = defaultTintColor
    self.symbolConfiguration = symbolConfiguration
    self.symbolWeight = symbolWeight
    self.treatsCustomImageAsTemplate = treatsCustomImageAsTemplate
    self.placeholderSymbolName = placeholderSymbolName
  }
}

extension FKIconViewAppearanceConfiguration {
  public static func == (lhs: FKIconViewAppearanceConfiguration, rhs: FKIconViewAppearanceConfiguration) -> Bool {
    lhs.backgroundStyle == rhs.backgroundStyle
      && lhs.symbolWeight == rhs.symbolWeight
      && lhs.treatsCustomImageAsTemplate == rhs.treatsCustomImageAsTemplate
      && lhs.placeholderSymbolName == rhs.placeholderSymbolName
  }
}

extension FKIconViewBackgroundStyle {
  public static func == (lhs: FKIconViewBackgroundStyle, rhs: FKIconViewBackgroundStyle) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      true
    case (.circle, .circle):
      true
    case (.roundedRect(let lRadius, _), .roundedRect(let rRadius, _)):
      lRadius == rRadius
    default:
      false
    }
  }

  var isNone: Bool {
    if case .none = self { true } else { false }
  }
}

/// Accessibility settings for ``FKIconView``.
public struct FKIconViewAccessibilityConfiguration: Sendable, Equatable {
  /// When `true`, the view is hidden from VoiceOver (decorative icons in list rows).
  public var isDecorative: Bool
  public var customLabel: String?
  public var customHint: String?

  public init(
    isDecorative: Bool = true,
    customLabel: String? = nil,
    customHint: String? = nil
  ) {
    self.isDecorative = isDecorative
    self.customLabel = customLabel
    self.customHint = customHint
  }
}

/// Layered configuration for ``FKIconView``.
public struct FKIconViewConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKIconViewLayoutConfiguration
  public var appearance: FKIconViewAppearanceConfiguration
  public var accessibility: FKIconViewAccessibilityConfiguration

  public init(
    layout: FKIconViewLayoutConfiguration = .init(),
    appearance: FKIconViewAppearanceConfiguration = .init(),
    accessibility: FKIconViewAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.accessibility = accessibility
  }
}

extension FKIconViewConfiguration {
  public static func == (lhs: FKIconViewConfiguration, rhs: FKIconViewConfiguration) -> Bool {
    lhs.layout == rhs.layout && lhs.accessibility == rhs.accessibility
  }
}

/// Thread-safe global defaults for ``FKIconView``.
public enum FKIconViewDefaults {
  @MainActor public static var configuration = FKIconViewConfiguration()
}
