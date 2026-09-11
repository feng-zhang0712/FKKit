import UIKit
import FKUIKit

/// Toolbar configuration variants (titles / visibility).
final class FKKeyboardToolbarConfigurationExampleViewController: FKKeyboardExamplePageViewController {
  private let navigator = FKKeyboardFormNavigator()
  private let toolbar = FKKeyboardToolbar()
  private let segment = UISegmentedControl(items: ["Full", "Nav only", "Done only", "Custom titles"])
  private var fields: [UITextField] = []
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toolbar configuration"
    addIntro(
      title: "FKKeyboardToolbarConfiguration",
      body: "Toggle navigation / done visibility and custom button titles via apply(_:)."
    )

    segment.selectedSegmentIndex = 0
    segment.addTarget(self, action: #selector(reloadToolbar), for: .valueChanged)
    contentStack.addArrangedSubview(segment)

    fields = [
      FKKeyboardExampleUI.makeTextField(placeholder: "One"),
      FKKeyboardExampleUI.makeTextField(placeholder: "Two"),
      FKKeyboardExampleUI.makeTextField(placeholder: "Three"),
    ]
    for (index, field) in fields.enumerated() {
      addField(title: "Input \(index + 1)", field: field)
    }

    navigator.fields = fields
    toolbar.install(asAccessoryOn: fields)
    toolbar.attach(to: navigator)
    reloadToolbar()

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(strategy: .adjustContentInsets)
    )
    controller.scrollView = scrollView
    avoidance = controller
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    avoidance?.stop()
    navigator.stopFocusTracking()
  }

  @objc
  private func reloadToolbar() {
    let configuration: FKKeyboardToolbarConfiguration
    switch segment.selectedSegmentIndex {
    case 1:
      configuration = .init(showsNavigationButtons: true, showsDoneButton: false)
    case 2:
      configuration = .init(showsNavigationButtons: false, showsDoneButton: true)
    case 3:
      configuration = .init(
        previousTitle: "Back",
        nextTitle: "Forward",
        doneTitle: "Close",
        showsNavigationButtons: true,
        showsDoneButton: true
      )
    default:
      configuration = .init()
    }
    toolbar.apply(configuration)
    navigator.notifyAvailability()
  }
}
