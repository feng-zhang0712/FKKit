import FKUIKit
import UIKit

final class FKPhotoPickerExampleBasicsViewController: FKPhotoPickerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Pick from photo library (default config)") { [weak self] in
      self?.pick(label: "library.default", configuration: .init())
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("Pick via closure API") { [weak self] in
      guard let self else { return }
      picker.pick(from: self, configuration: .init()) { result in
        Task { @MainActor in
          switch result {
          case let .success(items):
            self.showResults(items, label: "closure.success")
          case let .failure(error):
            self.showError(error, label: "closure.failure")
          }
        }
      }
    })

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoPicker.pick(from:configuration:)",
        description: "Uses PHPicker for the library. Dismiss without selecting maps to .cancelled. Results are delivered on the main actor.",
        body: body
      )
    )
    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.caption("Tip: tap Cancel in the picker to observe cancelled in the log.")
    )
    addClearLogButton()
  }
}
