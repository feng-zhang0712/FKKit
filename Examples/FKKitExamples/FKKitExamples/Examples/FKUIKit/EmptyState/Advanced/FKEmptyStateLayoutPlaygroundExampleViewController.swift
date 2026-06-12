import FKUIKit
import UIKit

/// Interactive layout playground for ``FKEmptyStateView`` — preview on top, tunable controls below.
final class FKEmptyStateLayoutPlaygroundExampleViewController: UIViewController {

  private let previewContainer: UIView = {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .tertiarySystemGroupedBackground
    container.layer.cornerRadius = 12
    container.layer.cornerCurve = .continuous
    container.clipsToBounds = true
    return container
  }()
  private var controlsScrollView: UIScrollView?

  // MARK: Controls

  private lazy var phaseControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Empty", "Loading", "Error"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var showDescriptionSwitch: UISwitch = {
    let control = UISwitch()
    control.isOn = true
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var showSecondarySwitch: UISwitch = {
    let control = UISwitch()
    control.isOn = true
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var contextControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Section", "List", "Full"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var densityControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Compact", "Regular", "Comfort"])
    control.selectedSegmentIndex = 1
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var axisControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Vertical", "Horizontal"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var alignmentControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Center", "Top"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var cornerStyleControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Fixed", "Capsule"])
    control.selectedSegmentIndex = 1
    control.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return control
  }()

  private lazy var segmentSpacingSwitch: UISwitch = {
    let control = UISwitch()
    control.addTarget(self, action: #selector(segmentSpacingToggled), for: .valueChanged)
    return control
  }()

  private lazy var verticalSpacingSlider = makeSlider(min: 0, max: 32, value: 12)
  private lazy var afterImageSlider = makeSlider(min: 0, max: 48, value: 20)
  private lazy var afterTitleSlider = makeSlider(min: 0, max: 32, value: 6)
  private lazy var afterDescriptionSlider = makeSlider(min: 0, max: 48, value: 24)
  private lazy var afterActionsSlotSlider = makeSlider(min: 0, max: 32, value: 8)
  private lazy var maxWidthSlider = makeSlider(min: 220, max: 420, value: 320)
  private lazy var imageSizeSlider = makeSlider(min: 32, max: 120, value: 80)
  private lazy var verticalOffsetSlider = makeSlider(min: -40, max: 80, value: 0)
  private lazy var insetVerticalSlider = makeSlider(min: 8, max: 48, value: 24)
  private lazy var insetHorizontalSlider = makeSlider(min: 8, max: 40, value: 20)
  private lazy var cornerRadiusSlider = makeSlider(min: 0, max: 24, value: 12)

  private lazy var verticalSpacingValueLabel = UILabel()
  private lazy var afterImageValueLabel = UILabel()
  private lazy var afterTitleValueLabel = UILabel()
  private lazy var afterDescriptionValueLabel = UILabel()
  private lazy var afterActionsSlotValueLabel = UILabel()
  private lazy var maxWidthValueLabel = UILabel()
  private lazy var imageSizeValueLabel = UILabel()
  private lazy var verticalOffsetValueLabel = UILabel()
  private lazy var insetVerticalValueLabel = UILabel()
  private lazy var insetHorizontalValueLabel = UILabel()
  private lazy var cornerRadiusValueLabel = UILabel()

  private var previewHeightConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout Playground"
    view.backgroundColor = .systemGroupedBackground
    buildLayout()
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Reset",
      style: .plain,
      target: self,
      action: #selector(resetControls)
    )
    segmentSpacingToggled()
    syncPreview()
  }

  private func buildLayout() {
    let controls = FKEmptyStateExamplePlaygroundSupport.makeControlsScrollStack(
      arrangedSubviews: buildControlSections()
    )
    controlsScrollView = controls

    let split = UIStackView(arrangedSubviews: [previewContainer, controls])
    split.translatesAutoresizingMaskIntoConstraints = false
    split.axis = .vertical
    split.spacing = 0
    view.addSubview(split)

    previewHeightConstraint = previewContainer.heightAnchor.constraint(
      equalTo: view.safeAreaLayoutGuide.heightAnchor,
      multiplier: 0.42
    )

    NSLayoutConstraint.activate([
      split.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      split.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      split.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      split.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      previewHeightConstraint!,
    ])
  }

  private func buildControlSections() -> [UIView] {
    let content = FKEmptyStateExamplePlaygroundSupport.sectionContainer(title: "Content & phase")
    content.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.caption(
      "Switch phase, description visibility, and secondary action."
    ))
    content.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(title: "Phase", control: phaseControl))
    content.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(
      title: "Description",
      control: showDescriptionSwitch
    ))
    content.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(
      title: "Secondary action",
      control: showSecondarySwitch
    ))

    let layout = FKEmptyStateExamplePlaygroundSupport.sectionContainer(title: "Layout presets")
    layout.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.caption(
      "Context presets fill in defaults when overrides are unset; density scales fallback spacing."
    ))
    layout.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(title: "Context", control: contextControl))
    layout.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(title: "Density", control: densityControl))
    layout.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(title: "Axis", control: axisControl))
    layout.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(title: "Alignment", control: alignmentControl))

    let spacing = FKEmptyStateExamplePlaygroundSupport.sectionContainer(title: "Spacing")
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.caption(
      "Vertical spacing is density-scaled. Segment overrides are applied as-is when enabled."
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(
      title: "Segment overrides",
      control: segmentSpacingSwitch
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Vertical spacing",
      slider: verticalSpacingSlider,
      valueLabel: verticalSpacingValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "After image",
      slider: afterImageSlider,
      valueLabel: afterImageValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "After title",
      slider: afterTitleSlider,
      valueLabel: afterTitleValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "After description",
      slider: afterDescriptionSlider,
      valueLabel: afterDescriptionValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    spacing.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "After actions slot",
      slider: afterActionsSlotSlider,
      valueLabel: afterActionsSlotValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))

    let geometry = FKEmptyStateExamplePlaygroundSupport.sectionContainer(title: "Size & position")
    geometry.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Max content width",
      slider: maxWidthSlider,
      valueLabel: maxWidthValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    geometry.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Image size",
      slider: imageSizeSlider,
      valueLabel: imageSizeValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    geometry.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Vertical offset",
      slider: verticalOffsetSlider,
      valueLabel: verticalOffsetValueLabel,
      format: { String(format: "%+.0f pt", $0) }
    ))
    geometry.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Insets (vertical)",
      slider: insetVerticalSlider,
      valueLabel: insetVerticalValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))
    geometry.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Insets (horizontal)",
      slider: insetHorizontalSlider,
      valueLabel: insetHorizontalValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))

    let buttons = FKEmptyStateExamplePlaygroundSupport.sectionContainer(title: "Button chrome")
    buttons.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.labeledRow(
      title: "Corner style",
      control: cornerStyleControl
    ))
    buttons.addArrangedSubview(FKEmptyStateExamplePlaygroundSupport.sliderRow(
      title: "Corner radius",
      slider: cornerRadiusSlider,
      valueLabel: cornerRadiusValueLabel,
      format: { String(format: "%.0f pt", $0) }
    ))

    return [content, layout, spacing, geometry, buttons]
  }

  private func makeSlider(min: Float, max: Float, value: Float) -> UISlider {
    let slider = UISlider()
    slider.minimumValue = min
    slider.maximumValue = max
    slider.value = value
    slider.addTarget(self, action: #selector(syncPreview), for: .valueChanged)
    return slider
  }

  @objc private func segmentSpacingToggled() {
    let enabled = segmentSpacingSwitch.isOn
    for slider in [afterImageSlider, afterTitleSlider, afterDescriptionSlider, afterActionsSlotSlider] {
      slider.isEnabled = enabled
      slider.alpha = enabled ? 1 : 0.45
    }
    syncPreview()
  }

  @objc private func resetControls() {
    phaseControl.selectedSegmentIndex = 0
    showDescriptionSwitch.isOn = true
    showSecondarySwitch.isOn = true
    contextControl.selectedSegmentIndex = 0
    densityControl.selectedSegmentIndex = 1
    axisControl.selectedSegmentIndex = 0
    alignmentControl.selectedSegmentIndex = 0
    cornerStyleControl.selectedSegmentIndex = 1
    segmentSpacingSwitch.isOn = false
    verticalSpacingSlider.value = 12
    afterImageSlider.value = 20
    afterTitleSlider.value = 6
    afterDescriptionSlider.value = 24
    afterActionsSlotSlider.value = 8
    maxWidthSlider.value = 320
    imageSizeSlider.value = 80
    verticalOffsetSlider.value = 0
    insetVerticalSlider.value = 24
    insetHorizontalSlider.value = 20
    cornerRadiusSlider.value = 12
    segmentSpacingToggled()
  }

  @objc private func syncPreview() {
    let imageSide = CGFloat(imageSizeSlider.value.rounded())
    let horizontalInset = CGFloat(insetHorizontalSlider.value.rounded())
    let verticalInset = CGFloat(insetVerticalSlider.value.rounded())

    var model = FKEmptyStateConfiguration.scenario(.noFavorites)
    model.phase = phaseFromControl()
    model.layout.context = contextFromControl()
    model.layout.density = densityFromControl()
    model.layout.axis = axisControl.selectedSegmentIndex == 1 ? .horizontal : .vertical
    model.layout.contentAlignment = alignmentControl.selectedSegmentIndex == 1 ? .top : .center
    model.layout.verticalSpacing = CGFloat(verticalSpacingSlider.value.rounded())
    model.layout.maxContentWidth = CGFloat(maxWidthSlider.value.rounded())
    model.layout.imageSize = CGSize(width: imageSide, height: imageSide)
    model.layout.verticalOffset = CGFloat(verticalOffsetSlider.value.rounded())
    model.layout.contentInsets = UIEdgeInsets(
      top: verticalInset,
      left: horizontalInset,
      bottom: verticalInset,
      right: horizontalInset
    )

    if segmentSpacingSwitch.isOn {
      model.layout.segmentSpacing.afterImage = CGFloat(afterImageSlider.value.rounded())
      model.layout.segmentSpacing.afterTitle = CGFloat(afterTitleSlider.value.rounded())
      model.layout.segmentSpacing.afterDescription = CGFloat(afterDescriptionSlider.value.rounded())
      model.layout.segmentSpacing.afterActionsSlot = CGFloat(afterActionsSlotSlider.value.rounded())
    } else {
      model.layout.segmentSpacing = FKEmptyStateSpacingConfiguration()
    }

    if !showDescriptionSwitch.isOn {
      model.content.description = nil
    }

    let primaryTitle = model.actions.primary?.title ?? "Browse catalog"
    if showSecondarySwitch.isOn {
      model.actions = FKEmptyStateActionSet(
        primary: FKEmptyStateAction(id: "browse", title: primaryTitle, kind: .primary),
        secondary: FKEmptyStateAction(id: "learn", title: "Learn more", kind: .secondary)
      )
    } else {
      model.actions = FKEmptyStateActionSet(
        primary: FKEmptyStateAction(id: "browse", title: primaryTitle, kind: .primary)
      )
    }

    if model.phase == .loading {
      model.content.loadingMessage = model.content.title
    }

    if model.phase == .error {
      model.content.setImage(UIImage(systemName: "exclamationmark.triangle"))
      model.content.title = "Something went wrong"
      model.content.description = showDescriptionSwitch.isOn
        ? "We could not load your favorites. Check your connection and try again."
        : nil
    }

    model.appearance.buttons.primary.cornerStyle = cornerStyleControl.selectedSegmentIndex == 1
      ? .capsule
      : .fixed(radius: CGFloat(cornerRadiusSlider.value.rounded()))

    cornerRadiusSlider.isEnabled = cornerStyleControl.selectedSegmentIndex == 0
    cornerRadiusSlider.alpha = cornerRadiusSlider.isEnabled ? 1 : 0.45
    axisControl.isEnabled = model.phase != .loading

    previewContainer.fk_applyEmptyState(model)
    refreshSliderLabels()
  }

  private func refreshSliderLabels() {
    verticalSpacingValueLabel.text = String(format: "%.0f pt", verticalSpacingSlider.value)
    afterImageValueLabel.text = String(format: "%.0f pt", afterImageSlider.value)
    afterTitleValueLabel.text = String(format: "%.0f pt", afterTitleSlider.value)
    afterDescriptionValueLabel.text = String(format: "%.0f pt", afterDescriptionSlider.value)
    afterActionsSlotValueLabel.text = String(format: "%.0f pt", afterActionsSlotSlider.value)
    maxWidthValueLabel.text = String(format: "%.0f pt", maxWidthSlider.value)
    imageSizeValueLabel.text = String(format: "%.0f pt", imageSizeSlider.value)
    verticalOffsetValueLabel.text = String(format: "%+.0f pt", verticalOffsetSlider.value)
    insetVerticalValueLabel.text = String(format: "%.0f pt", insetVerticalSlider.value)
    insetHorizontalValueLabel.text = String(format: "%.0f pt", insetHorizontalSlider.value)
    cornerRadiusValueLabel.text = String(format: "%.0f pt", cornerRadiusSlider.value)
  }

  private func phaseFromControl() -> FKEmptyStatePhase {
    switch phaseControl.selectedSegmentIndex {
    case 1: return .loading
    case 2: return .error
    default: return .empty
    }
  }

  private func contextFromControl() -> FKEmptyStateLayoutContext {
    switch contextControl.selectedSegmentIndex {
    case 1: return .list
    case 2: return .fullPage
    default: return .section
    }
  }

  private func densityFromControl() -> FKEmptyStateDensity {
    switch densityControl.selectedSegmentIndex {
    case 0: return .compact
    case 2: return .comfortable
    default: return .regular
    }
  }
}
