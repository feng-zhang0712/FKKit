import FKUIKit
import UIKit

final class FKPhotoPickerExampleVideoViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Video Picking"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Library video · fileURL + thumbnail") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.mediaTypes = .videos
      config.selection.limit = 1
      config.delivery = .imageAndFileURL
      self?.pick(label: "video.library", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("maxVideoBytes = 1_000_000 (expect fileTooLarge)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.mediaTypes = .videos
      config.selection.limit = 1
      config.video.maxVideoBytes = 1_000_000
      self?.pick(label: "video.maxBytes", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Camera video · 15s max duration") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.source = .camera
      config.mediaTypes = .videos
      config.selection.limit = 1
      config.video.maximumDuration = 15
      config.delivery = .fileURL
      self?.pick(label: "video.camera15s", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "Video handling (v1)",
        description: "Library videos are copied to a temp file without transcoding. image/thumbnail carries the first-frame preview; fileURL is required for upload.",
        body: body
      )
    )
    addClearLogButton()
  }
}
