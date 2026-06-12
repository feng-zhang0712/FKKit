import Foundation

/// ListKit-friendly row model for ``FKFormCellCaptchaCell``.
public struct FKFormCaptchaRow: Sendable, Equatable, Hashable {
  public var id: String
  public var text: String
  public var configuration: FKFormCellCaptchaConfiguration

  /// Creates a captcha row model.
  public init(
    id: String,
    text: String = "",
    configuration: FKFormCellCaptchaConfiguration
  ) {
    self.id = id
    self.text = text
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
