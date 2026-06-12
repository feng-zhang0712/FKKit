import Foundation
import UIKit
public struct FKCellNowPlayingRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellNowPlayingConfiguration
  public init(id: String, configuration: FKCellNowPlayingConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
