import UIKit

/// Sheet placement mode used by preferred-content sizing helpers.
public typealias FKSheetPresentationLayout = FKSheetPresentationConfiguration.Layout

public extension FKSheetPresentationConfiguration {
  /// Extra inset reserved inside the shell for the grabber on bottom/top sheet layouts.
  ///
  /// Matches ``FKContainerSheetPresentationController`` content-container insetting.
  @MainActor
  func grabberReservedInsets(for layout: FKSheetPresentationLayout) -> UIEdgeInsets {
    FKSheetGrabberLayout.reservedContentInsets(configuration: self, layout: layout)
  }

  /// Converts a pure content height into the shell (detent) height for the active reporting mode.
  ///
  /// When ``preferredContentSizeReporting`` is `.shellHeight`, returns `contentHeight` unchanged.
  /// For `.contentOnly` on bottom/top sheets, adds grabber and safe-area compensation consistent with
  /// ``layoutContentContainer()`` — without double-counting ``containerRespectsSafeArea`` detent padding.
  @MainActor
  func resolvedShellHeight(
    fromContentHeight contentHeight: CGFloat,
    layout: FKSheetPresentationLayout,
    containerSafeAreaInsets: UIEdgeInsets
  ) -> CGFloat {
    FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: contentHeight,
      configuration: self,
      layout: layout,
      containerSafeAreaInsets: containerSafeAreaInsets
    )
  }
}
