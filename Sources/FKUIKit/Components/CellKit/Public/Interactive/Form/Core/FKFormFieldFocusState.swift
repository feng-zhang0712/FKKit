import Foundation

/// Resolved focus and enablement state for form field chrome.
public enum FKFormFieldFocusState: Sendable, Equatable {
  case unfocused
  case focused
  case disabled
}
