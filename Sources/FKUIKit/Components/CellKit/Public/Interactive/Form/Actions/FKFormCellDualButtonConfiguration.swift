import Foundation

/// Layout direction for dual CTA buttons.
public enum FKFormDualButtonLayout: Sendable, Equatable {
  case horizontal
  case vertical
}

/// Configuration for ``FKFormCellDualButtonCell`` (X-50).
public struct FKFormCellDualButtonConfiguration: Sendable, Equatable {
  public var primaryTitle: String
  public var secondaryTitle: String
  public var layout: FKFormDualButtonLayout
  public var isPrimaryEnabled: Bool
  public var isSecondaryEnabled: Bool
  public var isPrimaryLoading: Bool
  public var isSecondaryLoading: Bool

  /// Creates a dual button row configuration.
  public init(
    primaryTitle: String,
    secondaryTitle: String,
    layout: FKFormDualButtonLayout = .horizontal,
    isPrimaryEnabled: Bool = true,
    isSecondaryEnabled: Bool = true,
    isPrimaryLoading: Bool = false,
    isSecondaryLoading: Bool = false
  ) {
    self.primaryTitle = primaryTitle
    self.secondaryTitle = secondaryTitle
    self.layout = layout
    self.isPrimaryEnabled = isPrimaryEnabled
    self.isSecondaryEnabled = isSecondaryEnabled
    self.isPrimaryLoading = isPrimaryLoading
    self.isSecondaryLoading = isSecondaryLoading
  }
}
