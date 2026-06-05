import UIKit

/// Shared shell ↔ hosted-content height conversion for layout engine and public sizing helpers.
enum FKSheetPreferredContentSizingMath {
  static func shellHeight(
    fromContentHeight contentHeight: CGFloat,
    configuration: FKSheetPresentationConfiguration,
    layout: FKSheetPresentationConfiguration.Layout,
    containerSafeAreaInsets: UIEdgeInsets
  ) -> CGFloat {
    guard configuration.preferredContentSizeReporting == .contentOnly else {
      return max(0, contentHeight)
    }

    var shellHeight = max(0, contentHeight)
    let grabberInsets = FKSheetGrabberLayout.reservedContentInsets(configuration: configuration, layout: layout)

    switch layout {
    case .bottomSheet:
      shellHeight += grabberInsets.top
      if configuration.safeAreaPolicy == .contentRespectsSafeArea {
        shellHeight += containerSafeAreaInsets.bottom
      }
    case .topSheet:
      shellHeight += grabberInsets.bottom
      if configuration.safeAreaPolicy == .contentRespectsSafeArea {
        shellHeight += containerSafeAreaInsets.top
      }
    case .center, .anchor, .edge:
      break
    }

    return shellHeight
  }

  static func hostedContentHeight(
    fromShellHeight shellHeight: CGFloat,
    configuration: FKSheetPresentationConfiguration,
    layout: FKSheetPresentationConfiguration.Layout,
    containerSafeAreaInsets: UIEdgeInsets
  ) -> CGFloat {
    var content = shellHeight
    let grabberInsets = FKSheetGrabberLayout.reservedContentInsets(configuration: configuration, layout: layout)

    switch layout {
    case .bottomSheet:
      content -= grabberInsets.top
      if configuration.safeAreaPolicy == .contentRespectsSafeArea {
        content -= containerSafeAreaInsets.bottom
      }
    case .topSheet:
      content -= grabberInsets.bottom
      if configuration.safeAreaPolicy == .contentRespectsSafeArea {
        content -= containerSafeAreaInsets.top
      }
    case .center, .anchor, .edge:
      break
    }

    return max(44, content)
  }
}
