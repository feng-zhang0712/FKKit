import UIKit

/// Layout parameters for ``FKTag``.
public struct FKTagLayoutConfiguration: Sendable, Equatable {
  public var size: FKChipSize
  public var horizontalPadding: CGFloat
  public var iconSpacing: CGFloat
  public var maxWidth: CGFloat?

  public init(
    size: FKChipSize = .s,
    horizontalPadding: CGFloat = 10,
    iconSpacing: CGFloat = 4,
    maxWidth: CGFloat? = nil
  ) {
    self.size = size
    self.horizontalPadding = horizontalPadding
    self.iconSpacing = iconSpacing
    self.maxWidth = maxWidth
  }
}

/// Visual styling for ``FKTag``.
public struct FKTagAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleFont: UIFont
  public var cornerStyle: FKChipCornerStyle

  public init(
    titleFont: UIFont = .systemFont(ofSize: 13, weight: .semibold),
    cornerStyle: FKChipCornerStyle = .capsule
  ) {
    self.titleFont = titleFont
    self.cornerStyle = cornerStyle
  }
}

extension FKTagAppearanceConfiguration {
  public static func == (lhs: FKTagAppearanceConfiguration, rhs: FKTagAppearanceConfiguration) -> Bool {
    lhs.cornerStyle == rhs.cornerStyle
  }
}

/// Accessibility settings for ``FKTag``.
public struct FKTagAccessibilityConfiguration: Sendable, Equatable {
  public var customLabel: String?

  public init(customLabel: String? = nil) {
    self.customLabel = customLabel
  }
}

/// Configuration for ``FKTag``.
public struct FKTagConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKTagLayoutConfiguration
  public var appearance: FKTagAppearanceConfiguration
  public var accessibility: FKTagAccessibilityConfiguration

  public init(
    layout: FKTagLayoutConfiguration = .init(),
    appearance: FKTagAppearanceConfiguration = .init(),
    accessibility: FKTagAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.accessibility = accessibility
  }
}

extension FKTagConfiguration {
  public static func == (lhs: FKTagConfiguration, rhs: FKTagConfiguration) -> Bool {
    lhs.layout == rhs.layout && lhs.accessibility == rhs.accessibility
  }
}

/// Thread-safe global defaults for ``FKTag``.
public enum FKTagDefaults {
  @MainActor public static var configuration = FKTagConfiguration()
}
