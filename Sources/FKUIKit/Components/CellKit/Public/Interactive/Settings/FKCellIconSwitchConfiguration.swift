import Foundation

/// Configuration for ``FKCellIconSwitchCell`` (I-02).
public struct FKCellIconSwitchConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent
  public var title: String
  public var subtitle: String?
  public var isOn: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon + switch row configuration.
  public init(
    icon: FKCellIconContent,
    title: String,
    subtitle: String? = nil,
    isOn: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.isOn = isOn
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
