import Foundation

/// Configuration for ``FKFormCellTimeCell`` (X-14, F-08).
public struct FKFormCellTimeConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var timeStyle: DateFormatter.Style
  public var minimumDate: Date?
  public var maximumDate: Date?
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a time field configuration.
  public init(
    layout: FKFormCellLayout = .cardStacked,
    label: String? = nil,
    timeStyle: DateFormatter.Style = .short,
    minimumDate: Date? = nil,
    maximumDate: Date? = nil,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.timeStyle = timeStyle
    self.minimumDate = minimumDate
    self.maximumDate = maximumDate
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-08)

public extension FKFormCellTimeConfiguration {
  /// Time picker field preset (F-08).
  static func time(
    layout: FKFormCellLayout = .cardStacked,
    label: String?,
    isRequired: Bool = false
  ) -> FKFormCellTimeConfiguration {
    FKFormCellTimeConfiguration(
      layout: layout,
      label: label,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }
}
