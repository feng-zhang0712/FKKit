import UIKit
import FKUIKit

enum FKSheetPresentationExampleHelpers {
  /// Returns the default sheet configuration used by most examples.
  @MainActor
  static func bottomSheetConfiguration() -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.shadow = .custom(color: .black, opacity: 0.18, radius: 16, offset: CGSize(width: 0, height: 8))
    return configuration
  }

  /// Returns a top-sheet configuration while preserving default sheet tuning.
  @MainActor
  static func topSheetConfiguration() -> FKSheetPresentationConfiguration {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.layout = .topSheet(configuration.sheet)
    configuration.shadow = .custom(color: .black, opacity: 0.18, radius: 16, offset: CGSize(width: 0, height: 8))
    return configuration
  }

  @MainActor
  static func present(
    from presentingViewController: UIViewController,
    title: String,
    configuration: FKSheetPresentationConfiguration,
    handlers: FKSheetPresentationLifecycleHandlers = .init()
  ) -> FKSheetPresentationController {
    let content = FKExampleLabelContentViewController(text: title)
    content.title = title
    return FKSheetPresentationController.present(
      contentController: content,
      from: presentingViewController,
      configuration: configuration,
      delegate: nil,
      handlers: handlers,
      animated: true,
      completion: nil
    )
  }
}

