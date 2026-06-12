import Foundation

/// Configuration for ``FKFormCellDragUploadCell`` (X-62).
public struct FKFormCellDragUploadConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool

  /// Creates a drag-and-drop upload zone configuration.
  public init(
    title: String = "Drag files here or tap to upload",
    subtitle: String? = "PDF, PNG, JPG up to 10 MB",
    isEnabled: Bool = true
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isEnabled = isEnabled
  }
}
