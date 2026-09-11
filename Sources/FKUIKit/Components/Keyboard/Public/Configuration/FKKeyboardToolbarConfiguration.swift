import Foundation
import UIKit

/// Configuration for ``FKKeyboardToolbar``.
public struct FKKeyboardToolbarConfiguration: Equatable {
  /// System or custom title for the Previous button.
  public var previousTitle: String

  /// System or custom title for the Next button.
  public var nextTitle: String

  /// System or custom title for the Done button.
  public var doneTitle: String

  /// When `true`, Previous / Next items are included.
  public var showsNavigationButtons: Bool

  /// When `true`, the Done item is included.
  public var showsDoneButton: Bool

  /// Toolbar style.
  public var barStyle: UIBarStyle

  /// When `true`, the bar is translucent.
  public var isTranslucent: Bool

  /// Creates a toolbar configuration.
  public init(
    previousTitle: String = "Previous",
    nextTitle: String = "Next",
    doneTitle: String = "Done",
    showsNavigationButtons: Bool = true,
    showsDoneButton: Bool = true,
    barStyle: UIBarStyle = .default,
    isTranslucent: Bool = true
  ) {
    self.previousTitle = previousTitle
    self.nextTitle = nextTitle
    self.doneTitle = doneTitle
    self.showsNavigationButtons = showsNavigationButtons
    self.showsDoneButton = showsDoneButton
    self.barStyle = barStyle
    self.isTranslucent = isTranslucent
  }
}
