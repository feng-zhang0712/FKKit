import FKCoreKit
import UIKit
@MainActor
public final class FKFormCellSplitFieldCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellSplitFieldRow
  public var onLeftTextChanged: ((String) -> Void)?; public var onRightTextChanged: ((String) -> Void)?
  private let leftField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
  private let rightField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric)); private let divider = FKDivider()
  private let stack = UIStackView()
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); commonInit() }
  public required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }
  public func apply(_ configuration: FKFormCellSplitFieldConfiguration) { apply(configuration, appearance: .default) }
  public func apply(_ configuration: FKFormCellSplitFieldConfiguration, appearance: FKCellAppearanceConfiguration = .default) {
    leftField.text = configuration.leftText; rightField.text = configuration.rightText
    leftField.placeholder = configuration.leftPlaceholder; rightField.placeholder = configuration.rightPlaceholder
    leftField.isEnabled = configuration.isEnabled; rightField.isEnabled = configuration.isEnabled
    backgroundColor = appearance.groupedBackgroundColor; contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
  }
  public func configure(with viewModel: FKFormCellSplitFieldRow) {
    apply(viewModel.configuration); leftField.text = viewModel.leftText; rightField.text = viewModel.rightText
  }
  public override func prepareForReuse() { super.prepareForReuse(); onLeftTextChanged = nil; onRightTextChanged = nil; selectionStyle = .none }
  private func commonInit() {
    backgroundColor = .clear; contentView.backgroundColor = .clear; selectionStyle = .none
    stack.axis = .horizontal; stack.distribution = .fillEqually; stack.spacing = 8; stack.translatesAutoresizingMaskIntoConstraints = false
    divider.translatesAutoresizingMaskIntoConstraints = false
    stack.addArrangedSubview(leftField); stack.addArrangedSubview(divider); stack.addArrangedSubview(rightField)
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      divider.widthAnchor.constraint(equalToConstant: 1),
    ])
    leftField.onEditingChanged = { [weak self] raw, _ in self?.onLeftTextChanged?(raw) }
    rightField.onEditingChanged = { [weak self] raw, _ in self?.onRightTextChanged?(raw) }
  }
}
