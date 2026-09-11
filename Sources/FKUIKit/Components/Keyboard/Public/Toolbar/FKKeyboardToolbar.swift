import UIKit

/// Standard keyboard accessory toolbar with Previous / Next / Done actions.
///
/// Assign instances to `UITextField.inputAccessoryView` / `UITextView.inputAccessoryView`.
/// Wire ``onPrevious``, ``onNext``, and ``onDone`` to a ``FKKeyboardFormNavigator`` (or custom logic).
@MainActor
open class FKKeyboardToolbar: UIToolbar {
  /// Invoked when Previous is tapped.
  public var onPrevious: (() -> Void)?

  /// Invoked when Next is tapped.
  public var onNext: (() -> Void)?

  /// Invoked when Done is tapped.
  public var onDone: (() -> Void)?

  /// Current configuration.
  public private(set) var configuration: FKKeyboardToolbarConfiguration

  private var previousItem: UIBarButtonItem?
  private var nextItem: UIBarButtonItem?
  private var doneItem: UIBarButtonItem?

  /// Creates a toolbar with the given configuration and width.
  public init(configuration: FKKeyboardToolbarConfiguration = .init(), width: CGFloat = UIScreen.main.bounds.width) {
    self.configuration = configuration
    super.init(frame: CGRect(x: 0, y: 0, width: width, height: 44))
    autoresizingMask = [.flexibleWidth]
    apply(configuration)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    nil
  }

  /// Rebuilds bar button items from `configuration`.
  public func apply(_ configuration: FKKeyboardToolbarConfiguration) {
    self.configuration = configuration
    barStyle = configuration.barStyle
    isTranslucent = configuration.isTranslucent

    var items: [UIBarButtonItem] = []

    if configuration.showsNavigationButtons {
      let previous = UIBarButtonItem(
        title: configuration.previousTitle,
        style: .plain,
        target: self,
        action: #selector(handlePrevious)
      )
      previous.accessibilityLabel = "Previous field"
      previousItem = previous
      items.append(previous)

      let next = UIBarButtonItem(
        title: configuration.nextTitle,
        style: .plain,
        target: self,
        action: #selector(handleNext)
      )
      next.accessibilityLabel = "Next field"
      nextItem = next
      items.append(next)
    } else {
      previousItem = nil
      nextItem = nil
    }

    items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

    if configuration.showsDoneButton {
      let done = UIBarButtonItem(
        title: configuration.doneTitle,
        style: .done,
        target: self,
        action: #selector(handleDone)
      )
      done.accessibilityLabel = "Done"
      doneItem = done
      items.append(done)
    } else {
      doneItem = nil
    }

    self.items = items
  }

  /// Enables or disables Previous / Next based on form position.
  public func updateNavigation(canGoPrevious: Bool, canGoNext: Bool) {
    previousItem?.isEnabled = canGoPrevious
    nextItem?.isEnabled = canGoNext
  }

  /// Convenience: binds toolbar actions to a form navigator and keeps button state in sync.
  ///
  /// Also starts ``FKKeyboardFormNavigator/startFocusTracking()`` so Previous / Next stay accurate
  /// when the user taps fields directly.
  ///
  /// Chains onto any existing ``FKKeyboardFormNavigator/onNavigationAvailabilityChange`` handler
  /// (does not replace it). Set your own observer **before** calling ``attach(to:)`` /
  /// ``install(onFormRoot:navigator:)``, or call ``updateNavigation(canGoPrevious:canGoNext:)``
  /// from a handler installed afterward.
  public func attach(to navigator: FKKeyboardFormNavigator) {
    onPrevious = { [weak navigator] in
      navigator?.focusPrevious()
    }
    onNext = { [weak navigator] in
      navigator?.focusNext()
    }
    onDone = { [weak navigator] in
      navigator?.resignFocus()
    }
    let existing = navigator.onNavigationAvailabilityChange
    navigator.onNavigationAvailabilityChange = { [weak self] canGoPrevious, canGoNext in
      existing?(canGoPrevious, canGoNext)
      self?.updateNavigation(canGoPrevious: canGoPrevious, canGoNext: canGoNext)
    }
    navigator.startFocusTracking()
    navigator.notifyAvailability()
  }

  /// Assigns this toolbar as `inputAccessoryView` on each text field / text view in `inputs`.
  public func install(asAccessoryOn inputs: [UIView]) {
    for input in inputs {
      if let field = input as? UITextField {
        field.inputAccessoryView = self
      } else if let view = input as? UITextView {
        view.inputAccessoryView = self
      }
    }
  }

  /// Discovers fields under `root`, installs this toolbar, and attaches a navigator.
  @discardableResult
  public func install(onFormRoot root: UIView, navigator: FKKeyboardFormNavigator) -> FKKeyboardFormNavigator {
    navigator.discoverFields(in: root)
    install(asAccessoryOn: navigator.fields)
    attach(to: navigator)
    return navigator
  }

  @objc
  private func handlePrevious() {
    onPrevious?()
  }

  @objc
  private func handleNext() {
    onNext?()
  }

  @objc
  private func handleDone() {
    onDone?()
  }
}
