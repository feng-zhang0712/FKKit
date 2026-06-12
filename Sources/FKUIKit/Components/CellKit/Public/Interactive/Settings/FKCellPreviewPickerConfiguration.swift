import Foundation
import UIKit
public struct FKCellPreviewPickerConfiguration: Sendable, Equatable {
  public var title: String; public var value: String; public var icon: FKCellIconContent?
  public var previewImage: UIImage?; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, value: String, icon: FKCellIconContent? = nil, previewImage: UIImage? = nil,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.value=value; self.icon=icon; self.previewImage=previewImage
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
extension FKCellPreviewPickerConfiguration {
  public static func == (lhs: FKCellPreviewPickerConfiguration, rhs: FKCellPreviewPickerConfiguration) -> Bool {
    lhs.title == rhs.title && lhs.value == rhs.value && lhs.icon == rhs.icon && lhs.previewImage === rhs.previewImage &&
      lhs.isEnabled == rhs.isEnabled && lhs.separatorPolicy == rhs.separatorPolicy && lhs.isLastInSection == rhs.isLastInSection
  }
}
