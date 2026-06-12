import FKCoreKit
import UIKit

/// Minimum and maximum amount fields in one row (X-56, F-15).
@MainActor
public final class FKFormCellRangeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellRangeRow

  public var onMinTextChanged: ((String) -> Void)?
  public var onMaxTextChanged: ((String) -> Void)?

  private let titleLabel = UILabel()
  private let minLabel = UILabel()
  private let maxLabel = UILabel()
  private let minField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .amount(maxIntegerDigits: 12, decimalDigits: 2)))
  private let maxField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .amount(maxIntegerDigits: 12, decimalDigits: 2)))
  private let rootStack = UIStackView()
  private let fieldsRow = UIStackView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellRangeConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellRangeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    minLabel.text = configuration.minLabel
    maxLabel.text = configuration.maxLabel
    minField.text = configuration.minText
    maxField.text = configuration.maxText
    minField.placeholder = configuration.minPlaceholder
    maxField.placeholder = configuration.maxPlaceholder
    minField.isEnabled = configuration.isEnabled
    maxField.isEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellRangeRow) {
    apply(viewModel.configuration)
    minField.text = viewModel.minText
    maxField.text = viewModel.maxText
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onMinTextChanged = nil
    onMaxTextChanged = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    fieldsRow.axis = .horizontal
    fieldsRow.spacing = 12
    fieldsRow.distribution = .fillEqually

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    minLabel.font = .preferredFont(forTextStyle: .caption1)
    minLabel.textColor = .secondaryLabel
    maxLabel.font = .preferredFont(forTextStyle: .caption1)
    maxLabel.textColor = .secondaryLabel

    let minColumn = UIStackView(arrangedSubviews: [minLabel, minField])
    minColumn.axis = .vertical
    minColumn.spacing = 4
    let maxColumn = UIStackView(arrangedSubviews: [maxLabel, maxField])
    maxColumn.axis = .vertical
    maxColumn.spacing = 4
    fieldsRow.addArrangedSubview(minColumn)
    fieldsRow.addArrangedSubview(maxColumn)

    rootStack.addArrangedSubview(titleLabel)
    rootStack.addArrangedSubview(fieldsRow)
    contentView.addSubview(rootStack)

    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      fieldsRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
    ])

    minField.onEditingChanged = { [weak self] (raw: String, _: String) in self?.onMinTextChanged?(raw) }
    maxField.onEditingChanged = { [weak self] (raw: String, _: String) in self?.onMaxTextChanged?(raw) }
  }
}
