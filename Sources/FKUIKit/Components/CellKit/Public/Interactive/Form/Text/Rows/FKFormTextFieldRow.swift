import Foundation

/// ListKit-friendly row model for ``FKFormCellTextFieldCell`` (F-01).
public struct FKFormTextFieldRow: Sendable, Equatable, Hashable {
  public var id: String
  public var text: String
  public var configuration: FKFormCellTextFieldConfiguration

  /// Creates a text field row model.
  public init(
    id: String,
    text: String = "",
    configuration: FKFormCellTextFieldConfiguration
  ) {
    self.id = id
    self.text = text
    self.configuration = configuration
  }

  /// Convenience builder for F-01.
  @MainActor
  public init(
    id: String,
    text: String = "",
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    isRequired: Bool = false
  ) {
    self.id = id
    self.text = text
    self.configuration = .textField(
      layout: layout,
      label: label,
      placeholder: placeholder,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

/// ListKit-friendly row model for password fields (F-02).
public struct FKFormPasswordRow: Sendable, Equatable, Hashable {
  public var id: String
  public var text: String
  public var configuration: FKFormCellTextFieldConfiguration

  /// Creates a password row model.
  public init(
    id: String,
    text: String = "",
    configuration: FKFormCellTextFieldConfiguration
  ) {
    self.id = id
    self.text = text
    self.configuration = configuration
  }

  /// Convenience builder for F-02.
  @MainActor
  public init(
    id: String,
    text: String = "",
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    isRequired: Bool = true
  ) {
    self.id = id
    self.text = text
    self.configuration = .password(
      layout: layout,
      label: label,
      placeholder: placeholder,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
