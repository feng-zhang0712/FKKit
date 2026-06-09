import FKUIKit
import UIKit

final class FKPhotoPickerExampleSourceChooserViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Source Chooser"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("source = .libraryOrCamera") { [weak self] in
      var config = FKPhotoPickerConfiguration.avatar()
      config.source = .libraryOrCamera
      self?.pick(label: "source.libraryOrCamera", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("source = .custom(.cameraBack)") { [weak self] in
      let config = FKPhotoPickerConfiguration(
        source: .custom(.cameraBack),
        mediaTypes: .images,
        selection: FKPhotoPickerSelectionPolicy(limit: 1),
        delivery: .imageAndFileURL
      )
      self?.pick(label: "source.custom.cameraBack", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("source = .photoLibrary only") { [weak self] in
      self?.pick(label: "source.photoLibrary", configuration: .init(source: .photoLibrary))
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoPickerSource",
        description: "libraryOrCamera presents FKActionSheet (UIAlertController fallback). custom(_) unwraps host-resolved sources for bespoke chooser flows.",
        body: body
      )
    )
    addClearLogButton()
  }
}
