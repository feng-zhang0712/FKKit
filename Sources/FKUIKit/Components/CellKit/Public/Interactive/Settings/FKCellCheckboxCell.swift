import FKCoreKit
import UIKit
@MainActor
public final class FKCellCheckboxCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellCheckboxRow
  public var onCheckedChanged: ((Bool) -> Void)?
  private let layout = FKCellStandardRowLayout(); private let checkbox = UIButton(type: .system)
  private var storedConfiguration = FKCellCheckboxConfiguration(title: "")
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKCellCheckboxConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKCellCheckboxConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    storedConfiguration = configuration
    layout.applyAppearance(appearance)
    updateCheckboxImage(isChecked: configuration.isChecked)
    checkbox.isEnabled = configuration.isEnabled
    layout.contentStack.setLeadingContent(
      configuration.placement == .leading ? checkbox : nil,
      width: configuration.placement == .leading ? FKCellLayoutMetrics.checkmarkColumnWidth : 0
    )
    layout.contentStack.setTitle(configuration.title); layout.contentStack.setSubtitle(configuration.subtitle)
    if configuration.placement == .trailing { layout.contentStack.setAccessoryViews([checkbox]) } else { layout.contentStack.setAccessoryViews([]) }
    layout.applyChrome(.init(groupConfiguration: nil, separatorPolicy: configuration.separatorPolicy, isLastInSection: configuration.isLastInSection, isEnabled: configuration.isEnabled), to: self)
    selectionStyle = configuration.togglesOnRowTap ? .default : .none
    accessibilityLabel = configuration.title; accessibilityTraits = configuration.isChecked ? [.selected, .button] : [.button]
  }
  public func configure(with viewModel: FKCellCheckboxRow) { apply(viewModel.configuration) }
  public override func prepareForReuse() { super.prepareForReuse(); onCheckedChanged = nil; layout.resetForReuse(); selectionStyle = .default }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear
    checkbox.translatesAutoresizingMaskIntoConstraints = false
    checkbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
    NSLayoutConstraint.activate([
      checkbox.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.checkmarkColumnWidth),
      checkbox.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.checkmarkColumnWidth),
    ])
    layout.install(in: contentView)
  }
  @objc private func checkboxTapped() { toggleChecked() }
  private func toggleChecked() {
    guard storedConfiguration.isEnabled else { return }
    let newValue = !storedConfiguration.isChecked
    storedConfiguration.isChecked = newValue; updateCheckboxImage(isChecked: newValue); onCheckedChanged?(newValue)
  }
  private func updateCheckboxImage(isChecked: Bool) {
    let name = isChecked ? "checkmark.square.fill" : "square"
    checkbox.setImage(UIImage(systemName: name), for: .normal)
  }
}
