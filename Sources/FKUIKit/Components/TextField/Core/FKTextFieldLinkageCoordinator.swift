//
// FKTextFieldLinkageCoordinator.swift
//
// Multi-text-field linkage coordinator (OTP style).
//

import UIKit

/// Coordinates multiple `FKTextField` instances for OTP-like flows.
@MainActor
public final class FKTextFieldLinkageCoordinator: NSObject {
  /// Linked text fields in order.
  public private(set) var textFields: [FKTextField]

  /// Creates a linkage coordinator.
  ///
  /// - Parameter textFields: Ordered fields from left to right.
  public init(textFields: [FKTextField]) {
    self.textFields = textFields
    super.init()
    bind()
  }

  /// Rebinds with a new text field list.
  public func updateTextFields(_ textFields: [FKTextField]) {
    self.textFields = textFields
    bind()
  }
}

private extension FKTextFieldLinkageCoordinator {
  func bind() {
    for (index, field) in textFields.enumerated() {
      field.onInputCompleted = { [weak self, weak field] _ in
        guard let self, let field else { return }
        self.moveToNextField(after: field, fallbackIndex: index)
      }
      field.forwardingDelegate = self
    }
  }

  func moveToNextField(after field: FKTextField, fallbackIndex: Int) {
    let currentIndex = textFields.firstIndex(of: field) ?? fallbackIndex
    let nextIndex = currentIndex + 1
    guard textFields.indices.contains(nextIndex) else {
      field.resignFirstResponder()
      return
    }
    textFields[nextIndex].becomeFirstResponder()
  }
}

extension FKTextFieldLinkageCoordinator: UITextFieldDelegate {
  public func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let field = textField as? FKTextField else { return true }
    if string.isEmpty, range.length == 1, field.rawText.isEmpty {
      let index = textFields.firstIndex(of: field) ?? 0
      let previous = index - 1
      if textFields.indices.contains(previous) {
        textFields[previous].becomeFirstResponder()
      }
    }
    return true
  }
}

