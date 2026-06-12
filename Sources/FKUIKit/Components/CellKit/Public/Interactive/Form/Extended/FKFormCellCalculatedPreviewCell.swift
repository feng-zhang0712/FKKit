import FKCoreKit
import UIKit

/// Input field with a live calculated preview below (X-68).
@MainActor
public final class FKFormCellCalculatedPreviewCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellCalculatedPreviewRow

  public var onTextChanged: ((String) -> Void)?

  private let titleLabel = UILabel()
  private let textField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .amount(maxIntegerDigits: 12, decimalDigits: 2)))
  private let previewLabel = UILabel()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellCalculatedPreviewConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellCalculatedPreviewConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    textField.text = configuration.text
    textField.placeholder = configuration.placeholder
    textField.isEnabled = configuration.isEnabled
    previewLabel.text = configuration.previewText
    previewLabel.isHidden = configuration.previewText.isEmpty

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellCalculatedPreviewRow) {
    var configuration = viewModel.configuration
    configuration.text = viewModel.text
    configuration.previewText = viewModel.previewText
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    previewLabel.font = .preferredFont(forTextStyle: .caption1)
    previewLabel.textColor = .secondaryLabel
    previewLabel.numberOfLines = 0

    contentView.addSubview(titleLabel)
    contentView.addSubview(textField)
    contentView.addSubview(previewLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    textField.translatesAutoresizingMaskIntoConstraints = false
    previewLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      previewLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 6),
      previewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])

    textField.onEditingChanged = { [weak self] (raw: String, _: String) in self?.onTextChanged?(raw) }
  }
}
