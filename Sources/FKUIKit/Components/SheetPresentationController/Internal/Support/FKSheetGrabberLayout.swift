import UIKit

/// Shared grabber inset math for shell layout and public sizing helpers.
enum FKSheetGrabberLayout {
  /// Extra inset applied to ``contentContainerView`` when the sheet grabber is visible.
  static func reservedContentInsets(
    configuration: FKSheetPresentationConfiguration,
    layout: FKSheetPresentationConfiguration.Layout
  ) -> UIEdgeInsets {
    guard configuration.sheet.prefersGrabberVisible else { return .zero }
    let padding = configuration.sheet.grabberTopInset
      + configuration.sheet.grabberSize.height
      + 8
    switch layout {
    case .bottomSheet:
      return .init(top: padding, left: 0, bottom: 0, right: 0)
    case .topSheet:
      return .init(top: 0, left: 0, bottom: padding, right: 0)
    case .center, .anchor, .edge:
      return .zero
    }
  }
}
