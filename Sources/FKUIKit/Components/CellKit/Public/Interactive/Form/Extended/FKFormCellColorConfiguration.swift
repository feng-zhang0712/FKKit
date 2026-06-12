import Foundation
import UIKit

/// Configuration for ``FKFormCellColorCell`` (X-57).
public struct FKFormCellColorConfiguration: Sendable, Equatable {
  public var label: String?
  public var selectedColor: UIColor
  public var showsHexField: Bool
  public var hexText: String?
  public var isEnabled: Bool

  public init(
    label: String? = "Color",
    selectedColor: UIColor = .systemBlue,
    showsHexField: Bool = true,
    hexText: String? = nil,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.selectedColor = selectedColor
    self.showsHexField = showsHexField
    self.hexText = hexText
    self.isEnabled = isEnabled
  }
}

extension FKFormCellColorConfiguration {
  public static func == (lhs: FKFormCellColorConfiguration, rhs: FKFormCellColorConfiguration) -> Bool {
    lhs.label == rhs.label && lhs.selectedColor == rhs.selectedColor &&
      lhs.showsHexField == rhs.showsHexField && lhs.hexText == rhs.hexText && lhs.isEnabled == rhs.isEnabled
  }
}
