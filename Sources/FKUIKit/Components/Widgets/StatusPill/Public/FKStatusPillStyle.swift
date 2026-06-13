import UIKit

/// Visual style for workflow/order status in ``FKStatusPill``.
public enum FKStatusPillStyle: Sendable, Equatable {
  /// Completed or approved states.
  case success
  /// Pending action or at-risk states.
  case warning
  /// Failed or rejected states.
  case error
  /// In-progress or informational states.
  case info
  /// Draft or unknown workflow states.
  case neutral
  /// Host-mapped appearance for backend-driven enums.
  case custom(FKStatusPillCustomAppearance)
}

/// Custom colors when ``FKStatusPillStyle/custom(_:)`` is used.
public struct FKStatusPillCustomAppearance: @unchecked Sendable, Equatable {
  public var backgroundColor: UIColor
  public var foregroundColor: UIColor
  /// When `nil`, the leading dot uses ``foregroundColor``.
  public var dotColor: UIColor?

  public init(
    backgroundColor: UIColor,
    foregroundColor: UIColor,
    dotColor: UIColor? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.dotColor = dotColor
  }
}

extension FKStatusPillCustomAppearance {
  public static func == (lhs: FKStatusPillCustomAppearance, rhs: FKStatusPillCustomAppearance) -> Bool {
    true
  }
}

/// Density preset for ``FKStatusPill`` (list trailing / order rows).
public enum FKStatusPillSize: Sendable, Equatable {
  /// 28 pt — default list trailing density.
  case s
  /// 32 pt — emphasized status pill.
  case m

  /// Resolved capsule height in points.
  public var height: CGFloat {
    switch self {
    case .s: 28
    case .m: 32
    }
  }
}

/// Layout parameters for ``FKStatusPill``.
public struct FKStatusPillLayoutConfiguration: Sendable, Equatable {
  public var size: FKStatusPillSize
  public var horizontalPadding: CGFloat
  /// Space between the leading dot and title when ``FKStatusPill/showsDot`` is `true`.
  public var dotSpacing: CGFloat
  /// Leading dot diameter (default 8 pt).
  public var dotDiameter: CGFloat
  public var maxWidth: CGFloat?

  public init(
    size: FKStatusPillSize = .s,
    horizontalPadding: CGFloat = 10,
    dotSpacing: CGFloat = 6,
    dotDiameter: CGFloat = 8,
    maxWidth: CGFloat? = nil
  ) {
    self.size = size
    self.horizontalPadding = horizontalPadding
    self.dotSpacing = dotSpacing
    self.dotDiameter = dotDiameter
    self.maxWidth = maxWidth
  }
}

/// Visual styling for ``FKStatusPill``.
public struct FKStatusPillAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleFont: UIFont
  public var textStyle: UIFont.TextStyle
  public var cornerStyle: FKChipCornerStyle
  /// Overrides dot tint for all styles; `nil` uses the style foreground (or custom dot color).
  public var dotColorOverride: UIColor?
  /// When `true` and ``FKStatusPill/style`` is `.info`, animates the leading dot with a shared pulse layer.
  public var pulsesDotForInfoStyle: Bool
  /// Caps Dynamic Type scaling for the title (defaults to ~two steps above the text style).
  public var maximumTitlePointSize: CGFloat?

  public init(
    titleFont: UIFont = .systemFont(ofSize: 12, weight: .semibold),
    textStyle: UIFont.TextStyle = .caption1,
    cornerStyle: FKChipCornerStyle = .capsule,
    dotColorOverride: UIColor? = nil,
    pulsesDotForInfoStyle: Bool = false,
    maximumTitlePointSize: CGFloat? = nil
  ) {
    self.titleFont = titleFont
    self.textStyle = textStyle
    self.cornerStyle = cornerStyle
    self.dotColorOverride = dotColorOverride
    self.pulsesDotForInfoStyle = pulsesDotForInfoStyle
    self.maximumTitlePointSize = maximumTitlePointSize
  }
}

extension FKStatusPillAppearanceConfiguration {
  public static func == (lhs: FKStatusPillAppearanceConfiguration, rhs: FKStatusPillAppearanceConfiguration) -> Bool {
    lhs.textStyle == rhs.textStyle
      && lhs.cornerStyle == rhs.cornerStyle
      && lhs.pulsesDotForInfoStyle == rhs.pulsesDotForInfoStyle
  }
}

/// Accessibility settings for ``FKStatusPill``.
public struct FKStatusPillAccessibilityConfiguration: Sendable, Equatable {
  public var customLabel: String?
  /// When `true`, appends the localized status suffix (for example, “Processing, status”).
  public var includesStatusSuffix: Bool

  public init(customLabel: String? = nil, includesStatusSuffix: Bool = true) {
    self.customLabel = customLabel
    self.includesStatusSuffix = includesStatusSuffix
  }
}

/// Layered configuration for ``FKStatusPill``.
public struct FKStatusPillConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKStatusPillLayoutConfiguration
  public var appearance: FKStatusPillAppearanceConfiguration
  public var accessibility: FKStatusPillAccessibilityConfiguration

  public init(
    layout: FKStatusPillLayoutConfiguration = .init(),
    appearance: FKStatusPillAppearanceConfiguration = .init(),
    accessibility: FKStatusPillAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.accessibility = accessibility
  }
}

extension FKStatusPillConfiguration {
  public static func == (lhs: FKStatusPillConfiguration, rhs: FKStatusPillConfiguration) -> Bool {
    lhs.layout == rhs.layout
      && lhs.appearance == rhs.appearance
      && lhs.accessibility == rhs.accessibility
  }
}

/// Thread-safe global defaults for ``FKStatusPill``.
public enum FKStatusPillDefaults {
  @MainActor public static var configuration = FKStatusPillConfiguration()
}

extension FKStatusPillStyle {
  /// Maps preset styles to shared workflow semantics; `custom` returns `nil`.
  public var semantic: FKWidgetStatusSemantic? {
    switch self {
    case .success: .success
    case .warning: .warning
    case .error: .error
    case .info: .info
    case .neutral: .neutral
    case .custom: nil
    }
  }
}
