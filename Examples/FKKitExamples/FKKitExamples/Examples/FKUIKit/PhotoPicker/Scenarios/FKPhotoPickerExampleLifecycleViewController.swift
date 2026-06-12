import FKUIKit
import UIKit

final class FKPhotoPickerExampleLifecycleViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Lifecycle & Temp Files"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Trigger alreadyPresenting") { [weak self] in
      guard let self else { return }
      let config = FKPhotoPickerConfiguration()
      Task { @MainActor in
        let firstTask = Task { @MainActor in
          do {
            _ = try await self.picker.pick(from: self, configuration: config)
          } catch {
            self.showError(error, label: "lifecycle.first")
          }
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        do {
          _ = try await self.picker.pick(from: self, configuration: config)
          self.log("lifecycle.second: unexpected success")
        } catch {
          self.showError(error, label: "lifecycle.second")
        }
        await firstTask.value
      }
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("tempFilePolicy = .deleteAfterCompletion(5s)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.selection.limit = 1
      config.tempFilePolicy = .deleteAfterCompletion(seconds: 5)
      self?.pick(label: "lifecycle.deleteAfter5s", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Host cleanup tracked file URLs") { [weak self] in
      self?.cleanupTrackedTempFiles()
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("allowsEmptySelection = true") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.allowsEmptySelection = true
      self?.pick(label: "lifecycle.emptyOK", configuration: config)
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "Session lifecycle",
        description: "Only one active session per FKPhotoPicker instance. Default tempFilePolicy is .hostResponsible — delete fileURL after upload using the cleanup button or FileManager.removeItem.",
        body: body
      )
    )
    addClearLogButton()
  }
}
