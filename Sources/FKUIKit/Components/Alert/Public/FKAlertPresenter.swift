import UIKit

/// Presents, queues, and dismisses FK-styled center alerts.
@MainActor
public final class FKAlertPresenter {
  /// Shared presenter instance.
  public static let shared = FKAlertPresenter()

  /// Optional lifecycle delegate.
  public weak var delegate: FKAlertDelegate?

  /// Whether an alert is currently visible (including during its dismiss animation).
  public var isPresenting: Bool { coordinator.isPresenting }

  private let coordinator = FKAlertCoordinator()

  private init() {}

  /// Presents an alert and suspends until the user selects an action or dismisses the sheet.
  public func present(
    _ content: FKAlertContent,
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = .init()
  ) async -> FKAlertResult {
    await coordinator.present(
      content: content,
      from: presenter,
      configuration: configuration,
      presenterDelegate: delegate,
      allowsDuplicateByID: true
    ) ?? .dismissed
  }

  /// Presents at most one alert per non-empty `content.id` while an instance is visible.
  public func presentOnce(
    _ content: FKAlertContent,
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = .init()
  ) async -> FKAlertResult? {
    var resolvedConfiguration = configuration
    resolvedConfiguration.queue = .presentOnceByID
    return await coordinator.present(
      content: content,
      from: presenter,
      configuration: resolvedConfiguration,
      presenterDelegate: delegate,
      allowsDuplicateByID: false
    )
  }

  /// Dismisses the active alert without invoking action handlers.
  public func dismiss(animated: Bool = true) {
    coordinator.dismissActive(animated: animated, result: .dismissed, invokeHandlers: false)
  }

  /// Applies a loading state to primary and destructive buttons on the currently visible alert.
  public func setLoading(_ isLoading: Bool) {
    coordinator.setLoading(isLoading)
  }
}
