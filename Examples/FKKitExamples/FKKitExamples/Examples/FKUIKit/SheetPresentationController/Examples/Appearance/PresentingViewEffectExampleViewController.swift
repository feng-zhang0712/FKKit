import UIKit
import FKUIKit

/// Applies a scale transform to the presenting view via ``FKSheetPresentationConfiguration/presentingViewEffect``.
final class PresentingViewEffectExampleViewController: FKSheetPresentationExamplePageViewController {
  private var scale: Float = 0.95

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Presenting view effect",
      subtitle: "Subtle scale on the presenting hierarchy while content is visible.",
      notes: """
      Disabled by default because custom container hierarchies may not expect transforms.
      Enable only when the presenting view controller owns the full screen chrome.
      """
    )

    addView(FKExampleControls.slider(title: "Scale", value: scale, range: 0.85...1.0, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.scale = v
    })

    addPrimaryButton(title: "Present with effect") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(320), .full]
      configuration.presentingViewEffect = .init(isEnabled: true, scale: CGFloat(self.scale))
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "Presenting effect", configuration: configuration)
    }
  }
}
