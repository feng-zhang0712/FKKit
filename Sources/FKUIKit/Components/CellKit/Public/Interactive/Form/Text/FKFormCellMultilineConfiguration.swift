import Foundation

/// Configuration for ``FKFormCellMultilineCell`` (F-04).
public struct FKFormCellMultilineConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var maxLength: Int?
  public var showsCounter: Bool
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a multiline text area configuration.
  public init(
    layout: FKFormCellLayout = .cardStacked,
    label: String? = nil,
    placeholder: String? = nil,
    maxLength: Int? = nil,
    showsCounter: Bool = true,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.maxLength = maxLength
    self.showsCounter = showsCounter
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-04)

public extension FKFormCellMultilineConfiguration {
  /// Multiline text area preset (F-04).
  static func multiline(
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    placeholder: String? = nil,
    maxLength: Int? = 500,
    isRequired: Bool = false
  ) -> FKFormCellMultilineConfiguration {
    FKFormCellMultilineConfiguration(
      layout: layout,
      label: label,
      placeholder: placeholder,
      maxLength: maxLength,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }
}
