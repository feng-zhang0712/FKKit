import FKUIKit
import UIKit

/// Live preview of layout styles, debounce, clear visibility, blur chrome, and programmatic text.
final class FKSearchExamplePlaygroundViewController: UIViewController {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Playground")
  private let previewHost = UIView()

  private let layoutControl = UISegmentedControl(items: ["Inline", "Nav", "Toolbar", "Minimal"])
  private let debounceSwitch = UISwitch()
  private let clearControl = UISegmentedControl(items: ["Edit+text", "Non-empty", "Never"])
  private let blurSwitch = UISwitch()
  private let minLengthStepper = UIStepper()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"
    view.backgroundColor = .systemGroupedBackground

    debounceSwitch.isOn = true
    blurSwitch.isOn = false
    minLengthStepper.minimumValue = 0
    minLengthStepper.maximumValue = 4
    minLengthStepper.stepValue = 1

    layoutControl.selectedSegmentIndex = 0
    clearControl.selectedSegmentIndex = 0

    layoutControl.addTarget(self, action: #selector(reloadConfiguration), for: .valueChanged)
    debounceSwitch.addTarget(self, action: #selector(reloadConfiguration), for: .valueChanged)
    clearControl.addTarget(self, action: #selector(reloadConfiguration), for: .valueChanged)
    blurSwitch.addTarget(self, action: #selector(reloadConfiguration), for: .valueChanged)
    minLengthStepper.addTarget(self, action: #selector(reloadConfiguration), for: .valueChanged)

    previewHost.backgroundColor = .tertiarySystemFill
    previewHost.layer.cornerRadius = 12
    previewHost.translatesAutoresizingMaskIntoConstraints = false
    searchBar.translatesAutoresizingMaskIntoConstraints = false
    previewHost.addSubview(searchBar)

    let controls = UIStackView(arrangedSubviews: [
      labeledRow("Layout style", layoutControl),
      labeledRow("Debounce enabled", debounceSwitch),
      labeledRow("Clear visibility", clearControl),
      labeledRow("Blur background", blurSwitch),
      labeledRow("Min query length", minLengthStepper),
    ])
    controls.axis = .vertical
    controls.spacing = 10

    let setTextButton = UIButton(type: .system)
    setTextButton.setTitle("setText(\"desk\", triggerSearchQuery)", for: .normal)
    setTextButton.addTarget(self, action: #selector(setSampleText), for: .touchUpInside)

    let accessoryButton = UIButton(type: .system)
    accessoryButton.setTitle("Attach inputAccessoryView toolbar", for: .normal)
    accessoryButton.addTarget(self, action: #selector(attachAccessory), for: .touchUpInside)

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Mutate configuration live. Exposes public `textField` for keyboard accessories."),
      previewHost,
      controls,
      setTextButton,
      accessoryButton,
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      previewHost.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
      searchBar.leadingAnchor.constraint(equalTo: previewHost.leadingAnchor, constant: 12),
      searchBar.trailingAnchor.constraint(equalTo: previewHost.trailingAnchor, constant: -12),
      searchBar.centerYAnchor.constraint(equalTo: previewHost.centerYAnchor),
    ])

    reloadConfiguration()
  }

  @objc private func reloadConfiguration() {
    searchBar.apply { config in
      switch layoutControl.selectedSegmentIndex {
      case 1:
        config = FKSearchBarDefaults.navigationBar()
      case 2:
        config.layout.style = .compactToolbar
        config.layout.minimumHeight = 36
        config.cancelButton.visibility = .never
      case 3:
        config.layout.style = .minimal
        config.layout.showsUnderline = true
        config.appearance.backgroundMaterial = .none
        config.cancelButton.visibility = .never
      default:
        config = FKSearchBarDefaults.inlineCard()
      }

      config.debounce.isDebounceEnabled = debounceSwitch.isOn
      config.debounce.minimumQueryLengthForSearchCallback = Int(minLengthStepper.value)

      config.clearButton.visibility = switch clearControl.selectedSegmentIndex {
      case 1: .whileNonEmpty
      case 2: .never
      default: .whileEditingNonEmpty
      }

      if blurSwitch.isOn {
        config.appearance.backgroundMaterial = .blur(.default)
      } else if config.layout.style != .minimal {
        config.appearance.backgroundMaterial = .solid
      }

      config.appearance.stateAppearances.focused.tintColor = .systemBlue
      config.appearance.stateAppearances.focused.borderColor = .systemBlue
      config.appearance.border = FKSearchBorderStyle(color: .separator, width: 1)
    }
  }

  @objc private func setSampleText() {
    searchBar.setText("desk", options: .withSearchQuery)
  }

  @objc private func attachAccessory() {
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
    toolbar.items = [
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard)),
    ]
    toolbar.sizeToFit()
    searchBar.textField.inputAccessoryView = toolbar
  }

  @objc private func dismissKeyboard() {
    searchBar.resignFirstResponder()
  }

  private func labeledRow(_ title: String, _ control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }
}
