import FKCoreKit
import UIKit

/// Text field with a microphone accessory for voice capture (X-59).
@MainActor
public final class FKFormCellVoiceInputCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellVoiceInputRow

  public var onTextChanged: ((String) -> Void)?
  public var onMicTap: (() -> Void)?

  private let titleLabel = UILabel()
  private let textField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: true))
  private let micButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellVoiceInputConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellVoiceInputConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    textField.text = configuration.text
    textField.placeholder = configuration.placeholder
    textField.isEnabled = configuration.isEnabled
    micButton.isEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellVoiceInputRow) {
    apply(viewModel.configuration)
    textField.text = viewModel.text
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    onMicTap = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    micButton.tintColor = .systemBlue
    micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)

    let row = UIStackView(arrangedSubviews: [textField, micButton])
    row.axis = .horizontal
    row.spacing = 8
    row.alignment = .center
    row.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(row)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      micButton.widthAnchor.constraint(equalToConstant: 44),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      row.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])

    textField.onEditingChanged = { [weak self] raw, _ in self?.onTextChanged?(raw) }
  }

  @objc private func micTapped() {
    onMicTap?()
  }
}
