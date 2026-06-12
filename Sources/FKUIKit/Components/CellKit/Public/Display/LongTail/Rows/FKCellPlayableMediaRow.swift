import Foundation
import UIKit
public struct FKCellPlayableMediaRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellPlayableMediaConfiguration
  public init(id: String, configuration: FKCellPlayableMediaConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
