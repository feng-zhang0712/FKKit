import UIKit
import FKUIKit

/// Shows `.containerRespectsSafeArea` for “card-like” overlays.
///
/// Key highlights:
/// - The container frame keeps distance from safe area.
/// - A good choice for center mode and card-style sheets.
final class SafeAreaContainerRespectsSafeAreaExampleViewController: FKSheetPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Safe area — containerRespectsSafeArea",
      subtitle: "Container stays away from safe area for a floating card look.",
      notes: "This avoids placing rounded corners under the notch or home indicator."
    )

    addPrimaryButton(title: "Present (center)") { [weak self] in
      guard let self else { return }
      var configuration = FKSheetPresentationConfiguration.default
      configuration.layout = .center(configuration.center)
      configuration.safeAreaPolicy = .containerRespectsSafeArea
      configuration.center.dismissEnabled = true
      _ = FKSheetPresentationExampleHelpers.present(from: self, title: "containerRespectsSafeArea", configuration: configuration)
    }
  }
}

