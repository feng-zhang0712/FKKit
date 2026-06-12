import Foundation
public struct FKFormCellEmailSuffixConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout; public var label: String?; public var placeholder: String?
  public var localPart: String; public var selectedSuffix: String; public var suffixOptions: [String]
  public var validation: FKFormFieldValidationPresentation; public var isEnabled: Bool
  public init(layout: FKFormCellLayout = .underline, label: String? = "Email", placeholder: String? = nil,
    localPart: String = "", selectedSuffix: String = "@example.com", suffixOptions: [String] = ["@example.com", "@company.com"],
    validation: FKFormFieldValidationPresentation = .init(), isEnabled: Bool = true) {
    self.layout=layout; self.label=label; self.placeholder=placeholder; self.localPart=localPart
    self.selectedSuffix=selectedSuffix; self.suffixOptions=suffixOptions; self.validation=validation; self.isEnabled=isEnabled
  }
}
