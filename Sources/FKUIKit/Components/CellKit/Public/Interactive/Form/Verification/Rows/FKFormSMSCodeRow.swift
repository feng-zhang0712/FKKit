import Foundation

/// ListKit-friendly row model for ``FKFormCellSMSCodeCell`` (F-03).
public struct FKFormSMSCodeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var code: String
  public var configuration: FKFormCellSMSCodeConfiguration

  /// Creates an SMS code row model.
  public init(
    id: String,
    code: String = "",
    configuration: FKFormCellSMSCodeConfiguration
  ) {
    self.id = id
    self.code = code
    self.configuration = configuration
  }

  /// Convenience builder for F-03.
  @MainActor
  public init(
    id: String,
    code: String = "",
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    codeLength: Int = 6,
    isRequired: Bool = true
  ) {
    self.id = id
    self.code = code
    self.configuration = .smsCode(
      layout: layout,
      label: label,
      placeholder: placeholder,
      codeLength: codeLength,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
