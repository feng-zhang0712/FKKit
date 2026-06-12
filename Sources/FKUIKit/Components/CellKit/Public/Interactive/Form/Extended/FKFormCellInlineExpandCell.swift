import FKCoreKit
import UIKit

/// Toggle that reveals an inline nested text field (X-64).
@MainActor
public final class FKFormCellInlineExpandCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellInlineExpandRow

  public var onExpandedChanged: ((Bool) -> Void)?
  public var onFieldTextChanged: ((String) -> Void)?

  private let toggleSwitch = UISwitch()
  private let toggleLabel = UILabel()
  private let fieldLabel = UILabel()
  private let textField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: true))
  private let fieldContainer = UIStackView()
  private let rootStack = UIStackView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellInlineExpandConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellInlineExpandConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    toggleLabel.text = configuration.toggleTitle
    fieldLabel.text = configuration.fieldLabel
    fieldLabel.isHidden = configuration.fieldLabel == nil
    textField.text = configuration.fieldText
    textField.placeholder = configuration.fieldPlaceholder
    toggleSwitch.isOn = configuration.isExpanded
    toggleSwitch.isEnabled = configuration.isEnabled
    textField.isEnabled = configuration.isEnabled
    fieldContainer.isHidden = !configuration.isExpanded

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.toggleTitle
  }

  public func configure(with viewModel: FKFormCellInlineExpandRow) {
    var configuration = viewModel.configuration
    configuration.isExpanded = viewModel.isExpanded
    configuration.fieldText = viewModel.fieldText
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onExpandedChanged = nil
    onFieldTextChanged = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .vertical
    rootStack.spacing = 12
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    let toggleRow = UIStackView(arrangedSubviews: [toggleLabel, toggleSwitch])
    toggleRow.axis = .horizontal
    toggleRow.alignment = .center
    toggleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    toggleSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

    fieldContainer.axis = .vertical
    fieldContainer.spacing = 4
    fieldLabel.font = .preferredFont(forTextStyle: .footnote)
    fieldLabel.textColor = .secondaryLabel
    fieldContainer.addArrangedSubview(fieldLabel)
    fieldContainer.addArrangedSubview(textField)

    rootStack.addArrangedSubview(toggleRow)
    rootStack.addArrangedSubview(fieldContainer)
    contentView.addSubview(rootStack)

    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])

    textField.onEditingChanged = { [weak self] raw, _ in self?.onFieldTextChanged?(raw) }
  }

  @objc private func toggleChanged() {
    fieldContainer.isHidden = !toggleSwitch.isOn
    onExpandedChanged?(toggleSwitch.isOn)
  }
}
