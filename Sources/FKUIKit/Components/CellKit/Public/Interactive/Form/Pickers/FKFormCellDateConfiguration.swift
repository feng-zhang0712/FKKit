import Foundation

/// Configuration for ``FKFormCellDateCell`` (X-13, F-08).
public struct FKFormCellDateConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var dateStyle: DateFormatter.Style
  public var minimumDate: Date?
  public var maximumDate: Date?
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a date field configuration.
  public init(
    layout: FKFormCellLayout = .cardStacked,
    label: String? = nil,
    dateStyle: DateFormatter.Style = .medium,
    minimumDate: Date? = nil,
    maximumDate: Date? = nil,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.dateStyle = dateStyle
    self.minimumDate = minimumDate
    self.maximumDate = maximumDate
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-08)

public extension FKFormCellDateConfiguration {
  /// Date picker field preset (F-08).
  static func date(
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    isRequired: Bool = false
  ) -> FKFormCellDateConfiguration {
    FKFormCellDateConfiguration(
      layout: layout,
      label: label,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }
}
