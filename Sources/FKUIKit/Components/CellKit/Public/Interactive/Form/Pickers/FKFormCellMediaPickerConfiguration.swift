import UIKit

/// Layout variant for ``FKFormCellMediaPickerCell`` (X-19, F-11).
public enum FKFormMediaPickerVariant: Sendable, Equatable {
  case avatar(displayName: String, imageURL: URL? = nil, image: UIImage? = nil)
  case thumbnail(fileName: String, image: FKCellImageContent)
  case file(fileName: String, fileSizeText: String, icon: FKCellIconContent)
}

/// Configuration for ``FKFormCellMediaPickerCell`` (X-19, F-11).
public struct FKFormCellMediaPickerConfiguration: @unchecked Sendable, Equatable {
  public var variant: FKFormMediaPickerVariant
  public var actionTitle: String
  public var showsDisclosure: Bool
  public var isEnabled: Bool

  /// Creates a media picker row configuration.
  public init(
    variant: FKFormMediaPickerVariant,
    actionTitle: String = "Change",
    showsDisclosure: Bool = false,
    isEnabled: Bool = true
  ) {
    self.variant = variant
    self.actionTitle = actionTitle
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
  }
}

extension FKFormCellMediaPickerConfiguration {
  public static func == (lhs: FKFormCellMediaPickerConfiguration, rhs: FKFormCellMediaPickerConfiguration) -> Bool {
    lhs.actionTitle == rhs.actionTitle
      && lhs.showsDisclosure == rhs.showsDisclosure
      && lhs.isEnabled == rhs.isEnabled
      && lhs.variant == rhs.variant
  }
}

extension FKFormMediaPickerVariant {
  public static func == (lhs: FKFormMediaPickerVariant, rhs: FKFormMediaPickerVariant) -> Bool {
    switch (lhs, rhs) {
    case let (.avatar(lName, lURL, lImage), .avatar(rName, rURL, rImage)):
      return lName == rName && lURL == rURL && lImage === rImage
    case let (.thumbnail(lName, lImage), .thumbnail(rName, rImage)):
      return lName == rName && lImage == rImage
    case let (.file(lName, lSize, lIcon), .file(rName, rSize, rIcon)):
      return lName == rName && lSize == rSize && lIcon == rIcon
    default:
      return false
    }
  }
}

// MARK: - Semantic preset (F-11)

public extension FKFormCellMediaPickerConfiguration {
  /// Avatar media picker preset (F-11).
  static func avatar(
    displayName: String,
    imageURL: URL? = nil,
    actionTitle: String = "Change Photo"
  ) -> FKFormCellMediaPickerConfiguration {
    FKFormCellMediaPickerConfiguration(
      variant: .avatar(displayName: displayName, imageURL: imageURL),
      actionTitle: actionTitle
    )
  }
}
