import Foundation

/// Picker row presentation style for ``FKFormCellPickerCell`` (X-11, X-12).
public enum FKFormPickerPresentation: Sendable, Equatable {
  /// Chevron down; host typically presents an action sheet or inline picker (X-11).
  case dropdown
  /// Chevron forward; host typically pushes a selection screen (X-12).
  case navigation
}
