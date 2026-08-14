import Foundation

/// Global defaults copied by new selection control instances.
@MainActor
public enum FKSelectionControlDefaults {
  /// Baseline for new ``FKCheckbox`` instances.
  public static var checkbox = FKCheckboxConfiguration()
  /// Baseline for new ``FKRadioButton`` instances.
  public static var radioButton = FKRadioButtonConfiguration()
  /// Baseline for new ``FKRadioGroup`` instances.
  public static var radioGroup = FKRadioGroupConfiguration()
  /// Baseline for new ``FKSelectionListChrome`` instances.
  public static var listChrome = FKSelectionListChromeConfiguration()
}
