import Foundation

/// ListKit-friendly row model for ``FKFormCellMultilineCell`` (F-04).
public struct FKFormMultilineRow: Sendable, Equatable, Hashable {
  public var id: String
  public var text: String
  public var configuration: FKFormCellMultilineConfiguration

  /// Creates a multiline row model.
  public init(
    id: String,
    text: String = "",
    configuration: FKFormCellMultilineConfiguration
  ) {
    self.id = id
    self.text = text
    self.configuration = configuration
  }

  /// Convenience builder for F-04.
  public init(
    id: String,
    text: String = "",
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    placeholder: String? = nil,
    maxLength: Int? = 500,
    isRequired: Bool = false
  ) {
    self.id = id
    self.text = text
    self.configuration = .multiline(
      layout: layout,
      label: label,
      placeholder: placeholder,
      maxLength: maxLength,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
