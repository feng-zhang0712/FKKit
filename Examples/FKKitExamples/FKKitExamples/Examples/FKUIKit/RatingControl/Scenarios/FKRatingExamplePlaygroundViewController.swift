import FKUIKit
import UIKit

/// Live surface for major ``FKRatingConfiguration`` groups.
final class FKRatingExamplePlaygroundViewController: FKRatingExampleScrollViewController {

  private let preview = FKRatingControl(configuration: FKRatingDefaults.configuration, value: 3)
  private let itemCountSlider = UISlider()
  private let itemSizeSlider = UISlider()
  private let spacingSlider = UISlider()
  private let modeControl = UISegmentedControl(items: ["Interactive", "Read-only"])
  private let stepControl = UISegmentedControl(items: ["Whole", "Half"])
  private let labelPlacementControl = UISegmentedControl(items: ["None", "Trailing", "Bottom"])
  private let presetControl = UISegmentedControl(items: ["Star", "Heart", "Thumb"])
  private let animationControl = UISegmentedControl(items: ["Bounce", "None"])
  private let valueSlider = UISlider()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    configureSliders()
    wireControls()

    [modeControl, stepControl, labelPlacementControl, presetControl, animationControl].forEach {
      $0.apportionsSegmentWidthsByContent = true
    }

    let previewBox = FKRatingExampleSupport.sectionContainer(title: "Preview")
    previewBox.addArrangedSubview(
      FKRatingExampleSupport.caption("Live preview — adjust controls below to validate combinations.")
    )
    previewBox.addArrangedSubview(FKRatingExampleSupport.embedRating(preview, alignment: .center))
    contentStack.addArrangedSubview(previewBox)

    let controlsBox = FKRatingExampleSupport.sectionContainer(title: "Configuration")
    [
      FKRatingExampleSupport.controlRow(title: "Mode", control: modeControl),
      FKRatingExampleSupport.controlRow(title: "Step", control: stepControl),
      FKRatingExampleSupport.controlRow(title: "Icon preset", control: presetControl),
      FKRatingExampleSupport.controlRow(title: "Label placement", control: labelPlacementControl),
      FKRatingExampleSupport.controlRow(title: "Selection animation", control: animationControl),
      FKRatingExampleSupport.controlRow(title: "Programmatic value", control: valueSlider),
      FKRatingExampleSupport.controlRow(title: "Item count", control: itemCountSlider),
      FKRatingExampleSupport.controlRow(title: "Item size", control: itemSizeSlider),
      FKRatingExampleSupport.controlRow(title: "Spacing", control: spacingSlider),
    ].forEach { controlsBox.addArrangedSubview($0) }
    contentStack.addArrangedSubview(controlsBox)

    applyConfiguration(animated: false)
  }

  private func configureSliders() {
    itemCountSlider.minimumValue = 3
    itemCountSlider.maximumValue = 10
    itemCountSlider.value = 5
    itemCountSlider.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)

    itemSizeSlider.minimumValue = 16
    itemSizeSlider.maximumValue = 40
    itemSizeSlider.value = 28
    itemSizeSlider.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)

    spacingSlider.minimumValue = 0
    spacingSlider.maximumValue = 16
    spacingSlider.value = 6
    spacingSlider.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)

    valueSlider.minimumValue = 0
    valueSlider.maximumValue = 5
    valueSlider.value = 3
    valueSlider.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.preview.setValue(Double(self.valueSlider.value), animated: true, sendsControlEvents: false)
    }, for: .valueChanged)
  }

  private func wireControls() {
    [modeControl, stepControl, labelPlacementControl, presetControl, animationControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }
    modeControl.selectedSegmentIndex = 0
    stepControl.selectedSegmentIndex = 0
    labelPlacementControl.selectedSegmentIndex = 0
    presetControl.selectedSegmentIndex = 0
    animationControl.selectedSegmentIndex = 0
  }

  private func applyConfiguration(animated: Bool = true) {
    var configuration = preview.configuration
    configuration.interaction.mode = modeControl.selectedSegmentIndex == 0 ? .interactive : .readOnly
    configuration.interaction.step = stepControl.selectedSegmentIndex == 1 ? .half : .whole
    configuration.layout.itemCount = Int(itemCountSlider.value.rounded())
    configuration.layout.itemSize = CGSize(
      width: CGFloat(itemSizeSlider.value),
      height: CGFloat(itemSizeSlider.value)
    )
    configuration.layout.itemSpacing = CGFloat(spacingSlider.value)
    configuration.layout.labelPlacement = {
      switch labelPlacementControl.selectedSegmentIndex {
      case 1: return .trailing
      case 2: return .bottom
      default: return .none
      }
    }()
    configuration.appearance.iconStyle = .preset({
      switch presetControl.selectedSegmentIndex {
      case 1: return .heart
      case 2: return .thumbUp
      default: return .star
      }
    }())
    configuration.motion.selectionAnimation = animationControl.selectedSegmentIndex == 0 ? .bounce : .none

    preview.configuration = configuration
    preview.maximumValue = Double(configuration.layout.itemCount)
    valueSlider.maximumValue = Float(configuration.layout.itemCount)
    preview.setValue(Double(valueSlider.value), animated: animated, sendsControlEvents: false)
  }
}
