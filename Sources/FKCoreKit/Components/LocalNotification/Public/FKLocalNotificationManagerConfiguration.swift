import Foundation

/// Runtime configuration for ``FKLocalNotificationManager``.
public struct FKLocalNotificationManagerConfiguration: Sendable, Equatable {
  /// Default foreground presentation when ``FKLocalNotificationManager/installDelegate(presentation:)`` is called.
  public var defaultPresentation: FKLocalNotificationPresentationOptions

  /// When `true`, installs the delegate adapter during initialization.
  ///
  /// Default is `false`; call ``FKLocalNotificationManager/installDelegate(presentation:)`` explicitly from the app delegate.
  public var automaticallyInstallDelegate: Bool

  /// Emits debug logs when scheduling fails.
  public var logSchedulingFailures: Bool

  /// When `true`, deeplink routing runs before ``FKLocalNotificationResponseHandler`` (default `false`).
  public var routeDeeplinkBeforeResponseHandler: Bool

  /// Default configuration: no automatic delegate installation.
  public static let `default` = FKLocalNotificationManagerConfiguration(
    defaultPresentation: .standard,
    automaticallyInstallDelegate: false,
    logSchedulingFailures: true,
    routeDeeplinkBeforeResponseHandler: false
  )

  /// Creates manager configuration.
  public init(
    defaultPresentation: FKLocalNotificationPresentationOptions = .standard,
    automaticallyInstallDelegate: Bool = false,
    logSchedulingFailures: Bool = true,
    routeDeeplinkBeforeResponseHandler: Bool = false
  ) {
    self.defaultPresentation = defaultPresentation
    self.automaticallyInstallDelegate = automaticallyInstallDelegate
    self.logSchedulingFailures = logSchedulingFailures
    self.routeDeeplinkBeforeResponseHandler = routeDeeplinkBeforeResponseHandler
  }
}
