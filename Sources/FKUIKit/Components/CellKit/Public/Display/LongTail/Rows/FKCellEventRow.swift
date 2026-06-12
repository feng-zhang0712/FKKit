import Foundation
import UIKit

/// ListKit-friendly row model for ``FKCellEventCell`` (D-51).
public struct FKCellEventRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellEventConfiguration

  public init(id: String, configuration: FKCellEventConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
