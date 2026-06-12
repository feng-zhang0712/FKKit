import Foundation
import UIKit
public struct FKCellConflictRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellConflictConfiguration
  public init(id: String, configuration: FKCellConflictConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
