import FKUIKit
import UIKit

final class FKPhotoPickerExampleDeliveryViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delivery Modes"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    for mode in deliveryModes {
      body.addArrangedSubview(FKPhotoPickerExampleUI.button(mode.title) { [weak self] in
        var config = FKPhotoPickerConfiguration()
        config.selection.limit = 1
        config.delivery = mode.delivery
        self?.pick(label: "delivery.\(mode.id)", configuration: config)
      })
    }

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoPickerDelivery",
        description: "Controls which fields are populated on FKPhotoPickerResult. fileURL exports land under temporaryDirectory/FKPhotoPicker/.",
        body: body
      )
    )
    addClearLogButton()
  }

  private var deliveryModes: [(id: String, title: String, delivery: FKPhotoPickerDelivery)] {
    [
      ("image", "delivery = .image", .image),
      ("data", "delivery = .compressedData", .compressedData),
      ("fileURL", "delivery = .fileURL", .fileURL),
      ("imageAndFileURL", "delivery = .imageAndFileURL (default)", .imageAndFileURL),
      ("imageAndData", "delivery = .imageAndData", .imageAndData),
    ]
  }
}
