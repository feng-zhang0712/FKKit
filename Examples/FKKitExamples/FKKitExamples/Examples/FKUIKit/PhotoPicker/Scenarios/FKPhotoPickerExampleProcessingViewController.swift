import FKUIKit
import UIKit

final class FKPhotoPickerExampleProcessingViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Compression & Privacy"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Downscale · maxPixelDimension 512") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.selection.limit = 1
      config.compression.maxPixelDimension = 512
      config.compression.jpegQuality = 0.8
      self?.pick(label: "process.downscale512", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Strip GPS · stripLocationEXIF = true (default)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.selection.limit = 1
      config.compression.stripLocationEXIF = true
      self?.pick(label: "process.stripGPS", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Keep metadata · stripLocationEXIF = false") { [weak self] in
      var config = FKPhotoPickerConfiguration.highQualitySingle()
      config.compression.stripLocationEXIF = false
      self?.pick(label: "process.keepGPS", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("highQualitySingle() · matchSource") { [weak self] in
      self?.pick(label: "process.highQuality", configuration: .highQualitySingle())
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Overflow · takeFirst(limit:)") { [weak self] in
      var config = FKPhotoPickerConfiguration.chatAttachments(max: 3)
      config.selection.overflowBehavior = .takeFirst(limit: 3)
      self?.pick(label: "process.overflowTakeFirst", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoCompressionOptions",
        description: "Large images are downsampled via CGImageSource before JPEG/HEIC encoding. Compare byteCount in the log after picking a high-resolution photo.",
        body: body
      )
    )
    addClearLogButton()
  }
}
