import Foundation
import UIKit
public struct FKCellPollResultRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellPollResultConfiguration
  public init(id: String, configuration: FKCellPollResultConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
