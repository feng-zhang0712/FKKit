import Foundation

/// Configuration for ``FKCellZeroResultsCell`` (D-88).
public struct FKCellZeroResultsConfiguration: Sendable, Equatable {
  public var iconSymbolName: String
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool

  public init(
    iconSymbolName: String = "magnifyingglass",
    title: String,
    subtitle: String? = nil,
    isEnabled: Bool = true
  ) {
    self.iconSymbolName = iconSymbolName
    self.title = title
    self.subtitle = subtitle
    self.isEnabled = isEnabled
  }
}
