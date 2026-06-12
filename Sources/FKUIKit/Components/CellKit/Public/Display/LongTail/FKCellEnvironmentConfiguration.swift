import Foundation
import UIKit
public struct FKCellEnvironmentConfiguration: Sendable, Equatable {
  public var name: String; public var token: String; public var dotColor: UIColor
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(name: String, token: String, dotColor: UIColor = .systemGreen, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.name=name; self.token=token; self.dotColor=dotColor; self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
extension FKCellEnvironmentConfiguration {
  public static func == (lhs: FKCellEnvironmentConfiguration, rhs: FKCellEnvironmentConfiguration) -> Bool {
    lhs.name == rhs.name && lhs.token == rhs.token && lhs.dotColor == rhs.dotColor &&
      lhs.isEnabled == rhs.isEnabled && lhs.separatorPolicy == rhs.separatorPolicy && lhs.isLastInSection == rhs.isLastInSection
  }
}
