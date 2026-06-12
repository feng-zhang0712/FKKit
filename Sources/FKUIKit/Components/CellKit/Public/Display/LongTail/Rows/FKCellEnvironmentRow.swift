import Foundation
import UIKit
public struct FKCellEnvironmentRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellEnvironmentConfiguration
  public init(id: String, configuration: FKCellEnvironmentConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
