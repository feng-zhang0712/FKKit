import Foundation

/// ListKit-friendly row model for ``FKFormCellMediaPickerCell`` (F-11).
public struct FKFormMediaPickerRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellMediaPickerConfiguration

  /// Creates a media picker row model.
  public init(id: String, configuration: FKFormCellMediaPickerConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  /// Convenience builder for F-11 avatar preset.
  public init(
    id: String,
    displayName: String,
    imageURL: URL? = nil,
    actionTitle: String = "Change Photo"
  ) {
    self.id = id
    self.configuration = .avatar(displayName: displayName, imageURL: imageURL, actionTitle: actionTitle)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
