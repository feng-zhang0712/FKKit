import FKUIKit
import UIKit

final class FKPhotoPickerExampleCameraViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Camera Capture"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Rear camera (.cameraBack)") { [weak self] in
      var config = FKPhotoPickerConfiguration.documentScan()
      config.source = .cameraBack
      self?.pick(label: "camera.back", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Front camera (.cameraFront)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.source = .cameraFront
      config.selection.limit = 1
      config.camera.allowsEditing = true
      self?.pick(label: "camera.front", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Camera with allowsEditing") { [weak self] in
      var config = FKPhotoPickerConfiguration.avatar()
      config.source = .camera
      config.camera.allowsEditing = true
      self?.pick(label: "camera.editing", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("documentScan() preset (camera + strip GPS)") { [weak self] in
      self?.pick(label: "camera.documentScan", configuration: .documentScan())
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "UIImagePickerController camera",
        description: "Camera flows run FKPermissions preflight (camera, and microphone when videos are included). Requires a physical device or simulator with camera support.",
        body: body
      )
    )
    addClearLogButton()
  }
}
