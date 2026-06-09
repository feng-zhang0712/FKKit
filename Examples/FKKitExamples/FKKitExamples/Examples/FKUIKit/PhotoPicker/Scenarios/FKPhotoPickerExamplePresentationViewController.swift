import FKUIKit
import UIKit

final class FKPhotoPickerExamplePresentationViewController: FKPhotoPickerExampleBaseViewController {
  private var popoverBarButtonItem: UIBarButtonItem?
  private var popoverAnchorButton: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"

    popoverAnchorButton = UIButton(type: .system)
    popoverAnchorButton?.setTitle("Popover anchor", for: .normal)
    popoverAnchorButton?.translatesAutoresizingMaskIntoConstraints = false
    popoverAnchorButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true

    let barItem = UIBarButtonItem(title: "Bar popover", style: .plain, target: self, action: #selector(pickFromBarButton))
    popoverBarButtonItem = barItem
    navigationItem.rightBarButtonItem = barItem

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("presentation = .automatic (library)") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.presentation.style = .automatic
      self?.pick(label: "presentation.automatic", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("presentation = .pageSheet") { [weak self] in
      var config = FKPhotoPickerConfiguration()
      config.presentation.style = .pageSheet
      self?.pick(label: "presentation.pageSheet", configuration: config)
    })
    body.addArrangedSubview(FKPhotoPickerExampleUI.button("presentation = .fullScreen (camera)") { [weak self] in
      var config = FKPhotoPickerConfiguration.documentScan()
      config.presentation.style = .fullScreen
      self?.pick(label: "presentation.fullScreen", configuration: config)
    })
    if let popoverAnchorButton {
      body.addArrangedSubview(popoverAnchorButton)
      popoverAnchorButton.addAction(UIAction { [weak self] _ in
        self?.pickFromViewAnchor()
      }, for: .touchUpInside)
    }

    contentStack.addArrangedSubview(
      FKPhotoPickerExampleUI.section(
        title: "FKPhotoPickerPresentation",
        description: "Popover style requires FKPhotoPickerPopoverAnchor at pick time. Use the bar button or anchor button above on iPad (or compact width popover when supported).",
        body: body
      )
    )
    addClearLogButton()
  }

  @objc private func pickFromBarButton() {
    guard let item = popoverBarButtonItem else { return }
    var config = FKPhotoPickerConfiguration()
    config.presentation.style = .popover
    pick(
      label: "presentation.popover.barItem",
      configuration: config,
      popoverAnchor: .barButtonItem(item)
    )
  }

  private func pickFromViewAnchor() {
    guard let popoverAnchorButton else { return }
    var config = FKPhotoPickerConfiguration.avatar()
    config.source = .libraryOrCamera
    config.presentation.style = .popover
    pick(
      label: "presentation.popover.sourceView",
      configuration: config,
      popoverAnchor: .sourceView(popoverAnchorButton)
    )
  }
}
