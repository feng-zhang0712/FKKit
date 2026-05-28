import UIKit
import FKUIKit

/// Shows detent-aware backdrop intensity via ``FKSheetPresentationConfiguration/SheetConfiguration/multiStageBackdrop``.
final class MultiStageBackdropExampleViewController: FKSheetPresentationExamplePageViewController {
  private var minimumAlpha: Float = 0.12
  private var maximumAlpha: Float = 0.45

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Multi-stage backdrop",
      subtitle: "Backdrop alpha follows the selected detent height.",
      notes: """
      Drag between detents to see the dim intensity change.
      This is FK's alternative to UIKit's largestUndimmedDetentIdentifier model.
      """
    )

    addView(FKExampleControls.slider(title: "Minimum alpha", value: minimumAlpha, range: 0...0.5, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.minimumAlpha = v
    })
    addView(FKExampleControls.slider(title: "Maximum alpha", value: maximumAlpha, range: 0.2...0.8, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.maximumAlpha = v
    })

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fraction(0.35), .medium, .large]
      configuration.sheet.multiStageBackdrop = .init(
        isEnabled: true,
        minimumAlpha: CGFloat(self.minimumAlpha),
        maximumAlpha: CGFloat(self.maximumAlpha)
      )
      configuration.backdropStyle = .dim(alpha: CGFloat(self.maximumAlpha))
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "Multi-stage backdrop", configuration: configuration)
    }
  }
}
