import FKUIKit
import UIKit

final class FKPhotoPickerExampleMultiSelectViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Multi-select & Progress"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("chatAttachments(max: 9)") { [weak self] in
      guard let self else { return }
      self.pick(
        label: "multi.chat9",
        configuration: .chatAttachments(max: 9),
        progressHandler: { processed, total in
          FKPhotoPickerExampleLog.shared.append("progress \(processed)/\(total)")
        }
      )
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Multi-select limit 4 + progress") { [weak self] in
      guard let self else { return }
      var config = FKPhotoPickerConfiguration.chatAttachments(max: 4)
      config.compression.maxPixelDimension = 1600
      self.pick(
        label: "multi.limit4",
        configuration: config,
        progressHandler: { processed, total in
          FKPhotoPickerExampleLog.shared.append("processing \(processed)/\(total)")
        }
      )
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "Selection policy & progress",
        description: "PHPicker selectionLimit mirrors configuration.selection.effectiveLimit (clamped 1…50). Progress callbacks fire on the main actor while assets are processed off the main thread.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.caption("Log order [0…n] matches picker selection order.")
    )
    addClearLogButton()
  }
}
