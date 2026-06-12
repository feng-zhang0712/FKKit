import Foundation

/// Static presentation settings for the SMS send button trailing accessory (X-17).
public struct FKFormSMSCodeButtonConfiguration: Sendable, Equatable {
  /// Title shown when the button is idle.
  public var title: String
  /// Countdown label format. Use `%d` for remaining seconds.
  public var countdownTitleFormat: String
  /// Default countdown duration in seconds after a successful send.
  public var countdownSeconds: Int

  /// Creates an SMS code button configuration.
  public init(
    title: String = "Send Code",
    countdownTitleFormat: String = "%ds",
    countdownSeconds: Int = 60
  ) {
    self.title = title
    self.countdownTitleFormat = countdownTitleFormat
    self.countdownSeconds = max(1, countdownSeconds)
  }
}
