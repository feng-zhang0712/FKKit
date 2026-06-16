import Foundation
import UIKit

/// Default implementation of ``FKBusinessUtilitiesProviding``.
public final class FKBusinessUtilities: FKBusinessUtilitiesProviding, @unchecked Sendable {
  /// Time formatting helper group.
  public let time: FKBusinessTimeFormatting
  /// Number formatting helper group.
  public let number: FKBusinessNumberFormatting
  /// Sensitive data masking helper group.
  public let mask: FKBusinessMasking
  /// Alert presentation and de-duplication helper group.
  public let alerts: FKBusinessAlertManaging
  /// Startup task orchestration helper group.
  public let startup: FKBusinessStartupTaskManaging

  /// Creates utilities facade with default helper implementations.
  ///
  /// - Parameters:
  ///   - i18n: Localization manager used by locale-aware formatters.
  ///   - alertManager: Shared alert manager for de-duplicated presentation.
  public init(
    i18n: FKBusinessLocalizing,
    alertManager: FKBusinessAlertManaging
  ) {
    let languageProvider: () -> String = { i18n.currentLanguageCode }
    time = FKBusinessTimeFormatter(languageCodeProvider: languageProvider)
    number = FKBusinessNumberFormatter(languageCodeProvider: languageProvider)
    mask = FKBusinessMasker()
    alerts = alertManager
    startup = FKBusinessStartupTaskManager()
  }
}
