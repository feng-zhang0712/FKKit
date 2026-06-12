import Foundation

/// Configuration for ``FKFormCellSwitchCaptionCell`` (X-39).
public struct FKFormCellSwitchCaptionConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?
  public var isOn: Bool
  public var isEnabled: Bool

  /// Creates a switch caption card row configuration.
  public init(
    title: String,
    subtitle: String? = nil,
    isOn: Bool = false,
    isEnabled: Bool = true
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isOn = isOn
    self.isEnabled = isEnabled
  }
}
