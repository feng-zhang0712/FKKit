import FKCoreKit
import UIKit

/// Read-only summary with a button to present a system picker (X-70).
@MainActor
public final class FKFormCellSystemPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellSystemPickerRow

  /// Called when the user taps the choose button.
  public var onChooseTap: (() -> Void)?

  private let titleLabel = UILabel()
  private let summaryLabel = UILabel()
  private let chooseButton = FKButton()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSystemPickerConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellSystemPickerConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    summaryLabel.text = configuration.summary
    chooseButton.setTitle(
      FKButtonLabelConfiguration(text: configuration.chooseButtonTitle, font: .systemFont(ofSize: 17), color: appearance.linkColor),
      for: .normal
    )
    chooseButton.isEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellSystemPickerRow) {
    var configuration = viewModel.configuration
    configuration.summary = viewModel.summary
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onChooseTap = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel
    summaryLabel.font = .preferredFont(forTextStyle: .body)
    summaryLabel.numberOfLines = 0

    chooseButton.translatesAutoresizingMaskIntoConstraints = false
    chooseButton.addTarget(self, action: #selector(handleChooseTap), for: .touchUpInside)

    contentView.addSubview(titleLabel)
    contentView.addSubview(summaryLabel)
    contentView.addSubview(chooseButton)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    summaryLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      summaryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      chooseButton.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
      chooseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      chooseButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      chooseButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  @objc private func handleChooseTap() {
    onChooseTap?()
  }
}
