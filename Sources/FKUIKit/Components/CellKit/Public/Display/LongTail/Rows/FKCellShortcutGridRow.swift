import Foundation
import UIKit
public struct FKCellShortcutGridRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellShortcutGridConfiguration
  public init(id: String, configuration: FKCellShortcutGridConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
