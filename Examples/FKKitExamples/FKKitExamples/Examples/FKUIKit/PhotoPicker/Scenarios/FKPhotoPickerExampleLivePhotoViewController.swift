import FKUIKit
import UIKit

final class FKPhotoPickerExampleLivePhotoViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Live Photo Policies"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("livePhoto = .stillImageOnly") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.mediaTypes = [.images, .livePhotos]
      config.livePhoto = .stillImageOnly
      config.selection.limit = 3
      self?.pick(label: "livePhoto.still", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("livePhoto = .skip") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.mediaTypes = [.images, .livePhotos]
      config.livePhoto = .skip
      config.selection.limit = 3
      self?.pick(label: "livePhoto.skip", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("livePhotos filter only") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.mediaTypes = .livePhotos
      config.selection.limit = 1
      self?.pick(label: "livePhoto.filterOnly", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKLivePhotoExportPolicy",
        description: "When .skip is active, Live Photos are omitted from multi-select results. Pick Live Photos from your library to compare still export vs skip behavior.",
        body: body
      )
    )
    addClearLogButton()
  }
}
