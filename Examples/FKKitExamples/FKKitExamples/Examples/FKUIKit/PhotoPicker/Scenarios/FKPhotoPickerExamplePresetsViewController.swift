import FKUIKit
import UIKit

final class FKPhotoPickerExamplePresetsViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presets & Convenience"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Preset · avatar()") { [weak self] in
      self?.pick(label: "preset.avatar", configuration: .avatar())
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Preset · chatAttachments(max: 9)") { [weak self] in
      self?.pick(label: "preset.chat", configuration: .chatAttachments(max: 9))
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Preset · documentScan()") { [weak self] in
      self?.pick(label: "preset.document", configuration: .documentScan())
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Preset · highQualitySingle()") { [weak self] in
      self?.pick(label: "preset.hq", configuration: .highQualitySingle())
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Static · FKPhotoPicker.pickAvatar(from:)") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        do {
          let avatar = try await FKPhotoPicker.pickAvatar(from: self)
          self.showResults([avatar], label: "static.pickAvatar")
        } catch {
          self.showError(error, label: "static.pickAvatar")
        }
      }
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Static · FKPhotoPicker.pickImages(from:limit:)") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        do {
          let images = try await FKPhotoPicker.pickImages(from: self, limit: 4)
          self.showResults(images, label: "static.pickImages")
        } catch {
          self.showError(error, label: "static.pickImages")
        }
      }
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Use FKPhotoPickerDefaults.configuration") { [weak self] in
      guard let self else { return }
      var config = FKPhotoPickerDefaults.configuration
      config.selection.limit = 1
      config.source = .photoLibrary
      self.pick(label: "defaults.configuration", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "Factory presets",
        description: "FKPhotoPickerPresets and FKPhotoPickerConfiguration shorthand cover avatar upload, chat attachments, document capture, and high-quality library picks.",
        body: body
      )
    )
    addClearLogButton()
  }
}
