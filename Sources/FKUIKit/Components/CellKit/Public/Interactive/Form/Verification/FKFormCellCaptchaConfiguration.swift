import Foundation

/// Configuration for ``FKFormCellCaptchaCell`` (X-16).
public struct FKFormCellCaptchaConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var captchaImage: FKCellImageContent?
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a captcha field configuration.
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    placeholder: String? = nil,
    captchaImage: FKCellImageContent? = nil,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.captchaImage = captchaImage
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}
