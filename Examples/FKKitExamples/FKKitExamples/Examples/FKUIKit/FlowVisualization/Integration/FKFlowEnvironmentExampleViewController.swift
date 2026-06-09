import FKCoreKit
import FKUIKit
import UIKit

/// RTL mirroring, Dynamic Type AX5, and Reduce Motion (no pulse).
final class FKFlowEnvironmentExampleViewController: FKFlowVisualizationScrollViewController {

  private let rtlIndicator = FKStepIndicator(items: FKFlowVisualizationExampleSupport.checkoutItems(), currentStepIndex: 2)
  private let motionIndicator: FKStepIndicator = {
    var config = FKStepIndicatorConfiguration()
    config.motion.pulsesCurrentNode = false
    return FKStepIndicator(configuration: config, items: FKFlowVisualizationExampleSupport.checkoutItems(), currentStepIndex: 1)
  }()
  private let typeTimeline = FKTimeline(items: FKFlowVisualizationExampleSupport.logisticsItems())
  private var selectedContentSizeCategory: UIContentSizeCategory = .large

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Environment"

    let rtlSwitch = UISwitch()
    rtlSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let direction: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
      self.rtlIndicator.semanticContentAttribute = direction
      self.rtlIndicator.setNeedsLayout()
    }, for: .valueChanged)

    let typeControl = UISegmentedControl(items: ["Large", "XXL", "AX3"])
    typeControl.selectedSegmentIndex = 0
    typeControl.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let category: UIContentSizeCategory = switch typeControl.selectedSegmentIndex {
      case 1: .extraExtraLarge
      case 2: .accessibilityExtraExtraLarge
      default: .large
      }
      self.applyContentSize(category)
    }, for: .valueChanged)

    var a11y = FKFlowAccessibilityConfiguration()
    a11y.stepLabelFormat = "Step {index}/{count}: {title} ({state})"
    a11y.selectableHint = "Double-tap to open this step."
    rtlIndicator.configuration.accessibility = a11y

    let rtlBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "Right-to-left")
    rtlBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Step order and connectors mirror when `semanticContentAttribute = .forceRightToLeft`."
    ))
    rtlBox.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(rtlIndicator))
    rtlBox.addArrangedSubview(FKFlowVisualizationExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    contentStack.addArrangedSubview(rtlBox)

    let motionBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "Reduce motion")
    motionBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "`motion.pulsesCurrentNode = false` disables the current-node pulse (also respects system Reduce Motion)."
    ))
    motionBox.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(motionIndicator))
    contentStack.addArrangedSubview(motionBox)

    let typeBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "Dynamic Type")
    typeBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Switch content size categories; the timeline relayouts with scaled fonts and nodes."
    ))
    typeBox.addArrangedSubview(FKFlowVisualizationExampleSupport.embedTimeline(typeTimeline, minHeight: 280))
    typeBox.addArrangedSubview(typeControl)
    contentStack.addArrangedSubview(typeBox)
  }

  private func applyContentSize(_ category: UIContentSizeCategory) {
    selectedContentSizeCategory = category
    let traits = UITraitCollection(preferredContentSizeCategory: category)
    var config = typeTimeline.configuration
    config.appearance.titleFont = UIFont.preferredFont(forTextStyle: .footnote)
      .fk_scaled(forTextStyle: .footnote, compatibleWith: traits)
    config.appearance.subtitleFont = UIFont.preferredFont(forTextStyle: .caption2)
      .fk_scaled(forTextStyle: .caption2, compatibleWith: traits)
    config.appearance.captionFont = UIFont.preferredFont(forTextStyle: .caption1)
      .fk_scaled(forTextStyle: .caption1, compatibleWith: traits)
    config.appearance.timestampFont = UIFont.preferredFont(forTextStyle: .caption2)
      .fk_scaled(forTextStyle: .caption2, compatibleWith: traits)
    typeTimeline.configuration = config
  }
}