import FKCoreKit
import FKUIKit
import UIKit

final class FKMediaGalleryExampleRemoteLoadingViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Remote Loading"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.progressiveLoading.showsProgressIndicator = true

    let delayedGallery = FKMediaGallery(
      configuration: configuration,
      imageLoader: FKImageExampleDelayedLoader()
    )
    delayedGallery.delegate = delegateLogger

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Loading & failure",
        description: "First page uses a delayed loader to expose progress chrome. Second page uses a 404 URL to trigger failure UI and didFailToLoad.",
        body: FKMediaGalleryExampleUI.button("Present loading demo") { [weak self] in
          guard let self else { return }
          do {
            try delayedGallery.present(
              from: self,
              items: FKMediaGalleryExampleCatalog.remoteLoadingItems(),
              configuration: configuration
            )
          } catch {
            FKMediaGalleryExampleLog.shared.append("present failed: \(error.localizedDescription)")
          }
        }
      ),
      at: 0
    )
  }
}
