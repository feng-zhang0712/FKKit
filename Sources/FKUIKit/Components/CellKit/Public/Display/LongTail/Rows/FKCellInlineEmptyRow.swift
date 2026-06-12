import Foundation
import UIKit
public struct FKCellInlineEmptyRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellInlineEmptyConfiguration
  public init(id: String, configuration: FKCellInlineEmptyConfiguration) {
    self.id = id; self.configuration = configuration
  }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
