import FKCoreKit
import UIKit

/// Color picker row with `UIColorWell` and optional hex field (X-57).
@MainActor
public final class FKFormCellColorCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellColorRow

  /// Called when the user picks a new color.
  public var onColorChanged: ((UIColor) -> Void)?

  private let titleLabel = UILabel()
  private let colorWell = UIColorWell()
  private let hexField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
  private let rowStack = UIStackView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellColorConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellColorConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    colorWell.selectedColor = configuration.selectedColor
    colorWell.isEnabled = configuration.isEnabled
    hexField.text = configuration.hexText
    hexField.isHidden = !configuration.showsHexField
    hexField.isEnabled = configuration.isEnabled
    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellColorRow) {
    apply(viewModel.configuration)
    hexField.text = viewModel.text
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onColorChanged = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    rowStack.axis = .horizontal
    rowStack.spacing = 12
    rowStack.alignment = .center
    rowStack.translatesAutoresizingMaskIntoConstraints = false

    colorWell.addTarget(self, action: #selector(colorChanged), for: .valueChanged)

    rowStack.addArrangedSubview(colorWell)
    rowStack.addArrangedSubview(hexField)
    contentView.addSubview(titleLabel)
    contentView.addSubview(rowStack)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rowStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      rowStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      colorWell.widthAnchor.constraint(equalToConstant: 44),
      colorWell.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  @objc private func colorChanged() {
    guard let color = colorWell.selectedColor else { return }
    onColorChanged?(color)
  }
}
