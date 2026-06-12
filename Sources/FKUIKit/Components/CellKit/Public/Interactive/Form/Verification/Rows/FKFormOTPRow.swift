import Foundation

/// ListKit-friendly row model for ``FKFormCellOTPCell`` (F-03).
public struct FKFormOTPRow: Sendable, Equatable, Hashable {
  public var id: String
  public var code: String
  public var configuration: FKFormCellOTPConfiguration

  /// Creates an OTP row model.
  public init(
    id: String,
    code: String = "",
    configuration: FKFormCellOTPConfiguration
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
    label: String? = nil,
    length: Int = 6,
    linkageID: FKFormCellLinkageID? = nil,
    isRequired: Bool = true
  ) {
    self.id = id
    self.code = code
    self.configuration = .otp(
      layout: layout,
      label: label,
      length: length,
      linkageID: linkageID,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
