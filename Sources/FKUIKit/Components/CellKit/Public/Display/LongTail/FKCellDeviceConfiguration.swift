import Foundation
public struct FKCellDeviceConfiguration: Sendable, Equatable {
  public var deviceName: String; public var statusText: String; public var statusStyle: FKStatusPillStyle
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(deviceName: String, statusText: String, statusStyle: FKStatusPillStyle = .info, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.deviceName=deviceName; self.statusText=statusText; self.statusStyle=statusStyle
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
