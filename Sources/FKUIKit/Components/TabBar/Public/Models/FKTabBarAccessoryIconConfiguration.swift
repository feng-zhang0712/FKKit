import UIKit

/// SF Symbol weight for ``FKTabBarAccessoryIconConfiguration`` trailing icons.
public enum FKTabBarAccessorySymbolWeight: Equatable, Sendable {
  case regular
  case medium
  case semibold
  case bold

  var uiImageWeight: UIImage.SymbolWeight {
    switch self {
    case .regular: return .regular
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    }
  }
}

/// Layout and tint for a trailing accessory icon rendered via ``FKButton/setTrailingImage(_:for:)``.
public struct FKTabBarAccessoryIconStyle: Equatable {
  /// Point size for SF Symbol accessories.
  public var pointSize: CGFloat
  /// Symbol weight when ``FKTabBarImageSource/systemSymbol(name:)`` is used.
  public var weight: FKTabBarAccessorySymbolWeight
  /// Template tint; `nil` uses the resolved title color at apply time.
  public var tintColor: UIColor?
  /// Optional fixed layout size; `nil` uses a square of ``pointSize``.
  public var fixedSize: CGSize?
  /// Spacing between title/icon content and the trailing icon.
  public var spacingToTitle: CGFloat

  /// Creates a trailing accessory icon style.
  public init(
    pointSize: CGFloat = 14,
    weight: FKTabBarAccessorySymbolWeight = .semibold,
    tintColor: UIColor? = nil,
    fixedSize: CGSize? = nil,
    spacingToTitle: CGFloat = 4
  ) {
    self.pointSize = max(1, pointSize)
    self.weight = weight
    self.tintColor = tintColor
    self.fixedSize = fixedSize
    self.spacingToTitle = max(0, spacingToTitle)
  }
}

extension FKTabBarAccessoryIconStyle: @unchecked Sendable {}

/// Trailing accessory icon with optional per-state overrides (`normal` / `selected` / `disabled`).
///
/// Host code owns animation and expansion visuals (for example chevron rotation) via ``FKTabBar/visibleItemAccessoryView(at:)``.
public struct FKTabBarAccessoryIconConfiguration: Equatable {
  /// One visual state for the trailing icon.
  public struct State: Equatable {
    public var source: FKTabBarImageSource?
    public var style: FKTabBarAccessoryIconStyle

    /// Creates a trailing icon state.
    public init(
      source: FKTabBarImageSource? = nil,
      style: FKTabBarAccessoryIconStyle = .init()
    ) {
      self.source = source
      self.style = style
    }
  }

  public var normal: State
  public var selected: State?
  public var disabled: State?

  /// Creates a trailing accessory icon configuration.
  public init(
    normal: State = .init(),
    selected: State? = nil,
    disabled: State? = nil
  ) {
    self.normal = normal
    self.selected = selected
    self.disabled = disabled
  }

  /// Convenience factory for a single SF Symbol used in every control state.
  public static func systemSymbol(
    _ name: String,
    style: FKTabBarAccessoryIconStyle = .init()
  ) -> FKTabBarAccessoryIconConfiguration {
    FKTabBarAccessoryIconConfiguration(
      normal: .init(source: .systemSymbol(name: name), style: style)
    )
  }

  /// Resolves the effective state for the current selection/enabled flags.
  public func resolved(isSelected: Bool, isEnabled: Bool) -> State {
    if !isEnabled {
      return disabled ?? normal
    }
    if isSelected {
      return selected ?? normal
    }
    return normal
  }
}

extension FKTabBarAccessoryIconConfiguration: @unchecked Sendable {}
