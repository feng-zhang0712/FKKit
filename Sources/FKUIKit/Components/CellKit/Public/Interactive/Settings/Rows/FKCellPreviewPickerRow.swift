import Foundation
import UIKit
public struct FKCellPreviewPickerRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellPreviewPickerConfiguration
  public init(id: String, configuration: FKCellPreviewPickerConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id); hasher.combine(configuration.previewImage) }
}
