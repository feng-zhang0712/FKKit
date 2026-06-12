import FKCoreKit
import UIKit
@MainActor
public final class FKCellStepperCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellStepperRow
  public var onValueChanged: ((Double) -> Void)?
  private let layout = FKCellStandardRowLayout(); private let stepper = UIStepper(); private var isApplying = false
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellStepperConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellStepperConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0); layout.contentStack.setTitle(configuration.title)
    stepper.minimumValue = configuration.minimumValue; stepper.maximumValue = configuration.maximumValue; stepper.stepValue = configuration.stepValue
    isApplying = true; stepper.value = configuration.value; isApplying = false
    stepper.isEnabled = configuration.isEnabled
    layout.contentStack.setAccessoryViews([stepper])
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = .none; accessibilityLabel = configuration.title
  }
  public func configure(with viewModel: FKCellStepperRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onValueChanged = nil; layout.resetForReuse(); selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged); layout.install(in: contentView)
  }
  @objc private func stepperChanged() { guard !isApplying else { return }; onValueChanged?(stepper.value) }
}
