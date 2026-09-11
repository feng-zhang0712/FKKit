import UIKit

/// Coordinates previous / next / done focus movement among an ordered list of responders.
@MainActor
public final class FKKeyboardFormNavigator {
  /// Ordered focusable fields. When empty, ``discoverFields(in:)`` may populate from a root view.
  public var fields: [UIView] = [] {
    didSet { notifyAvailability() }
  }

  /// Invoked when ``canGoPrevious`` / ``canGoNext`` may have changed.
  public var onNavigationAvailabilityChange: ((_ canGoPrevious: Bool, _ canGoNext: Bool) -> Void)?

  private let focusTrackingStorage = FocusTrackingStorage()

  /// Creates an empty navigator.
  public init(fields: [UIView] = []) {
    self.fields = fields
  }

  deinit {
    let center = NotificationCenter.default
    focusTrackingStorage.tokens.forEach { center.removeObserver($0) }
    focusTrackingStorage.tokens.removeAll()
  }

  /// Replaces ``fields`` with text inputs discovered under `root` (stable depth-first order).
  public func discoverFields(in root: UIView) {
    var found: [UIView] = []
    func visit(_ view: UIView) {
      if view is UITextField || view is UITextView, view.canBecomeFirstResponder {
        found.append(view)
      }
      for sub in view.subviews {
        visit(sub)
      }
    }
    visit(root)
    fields = found
  }

  /// Observes text begin-editing notifications so toolbar state stays correct when the user taps fields.
  ///
  /// Idempotent. Call ``stopFocusTracking()`` when the screen disappears if you want to release observers early.
  public func startFocusTracking() {
    guard focusTrackingStorage.tokens.isEmpty else { return }
    focusTrackingStorage.tokens = FKKeyboardEditingObservation.addBeginEditingObservers { [weak self] view in
      Task { @MainActor in
        guard let self, self.fields.contains(where: { $0 === view }) else { return }
        self.notifyAvailability()
      }
    }
    notifyAvailability()
  }

  /// Stops begin-editing observation started by ``startFocusTracking()``.
  public func stopFocusTracking() {
    FKKeyboardEditingObservation.remove(&focusTrackingStorage.tokens)
  }

  /// Index of the current first responder in ``fields``, if any.
  public var focusedIndex: Int? {
    guard let responder = fields.first(where: { $0.isFirstResponder }) else { return nil }
    return fields.firstIndex(where: { $0 === responder })
  }

  /// Whether a previous field exists relative to the current focus.
  public var canGoPrevious: Bool {
    guard let index = focusedIndex else { return false }
    return index > 0
  }

  /// Whether a next field exists relative to the current focus.
  public var canGoNext: Bool {
    guard let index = focusedIndex else { return !fields.isEmpty }
    return index < fields.count - 1
  }

  /// Moves focus to the previous field when possible.
  @discardableResult
  public func focusPrevious() -> Bool {
    guard let index = focusedIndex, index > 0 else { return false }
    return focusField(at: index - 1)
  }

  /// Moves focus to the next field when possible.
  @discardableResult
  public func focusNext() -> Bool {
    if let index = focusedIndex {
      guard index < fields.count - 1 else { return false }
      return focusField(at: index + 1)
    }
    return focusField(at: 0)
  }

  /// Resigns first responder for the focused field (or ends editing on the first available window root).
  public func resignFocus() {
    if let focused = fields.first(where: \.isFirstResponder) {
      focused.resignFirstResponder()
    } else {
      fields.first?.window?.endEditing(true)
    }
    notifyAvailability()
  }

  /// Makes the field at `index` first responder.
  @discardableResult
  public func focusField(at index: Int) -> Bool {
    guard fields.indices.contains(index) else { return false }
    let field = fields[index]
    let became = field.becomeFirstResponder()
    notifyAvailability()
    return became
  }

  /// Handles a keyboard Return press for `field`.
  ///
  /// Call from `textFieldShouldReturn(_:)` (or equivalent). Advances to the next field when possible;
  /// otherwise resigns focus. Returns `true` when the event was handled.
  @discardableResult
  public func handleReturn(from field: UIView) -> Bool {
    guard let index = fields.firstIndex(where: { $0 === field }) else { return false }
    if index < fields.count - 1 {
      return focusField(at: index + 1)
    }
    resignFocus()
    return true
  }

  /// Recomputes and emits navigation availability (call after external focus changes).
  public func notifyAvailability() {
    onNavigationAvailabilityChange?(canGoPrevious, canGoNext)
  }
}

private final class FocusTrackingStorage: @unchecked Sendable {
  var tokens: [NSObjectProtocol] = []
}
