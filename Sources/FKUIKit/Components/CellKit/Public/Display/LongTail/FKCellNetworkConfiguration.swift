import Foundation
public struct FKCellNetworkConfiguration: Sendable, Equatable {
  public var networkName: String; public var statusText: String; public var statusStyle: FKStatusPillStyle
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(networkName: String, statusText: String, statusStyle: FKStatusPillStyle = .info, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.networkName=networkName; self.statusText=statusText; self.statusStyle=statusStyle
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
