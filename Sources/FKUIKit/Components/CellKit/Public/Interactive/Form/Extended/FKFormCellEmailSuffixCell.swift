import FKCoreKit
import UIKit

/// Email field with configurable domain suffix chip (X-54, F-14).
@MainActor
public final class FKFormCellEmailSuffixCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellEmailSuffixRow

  /// Called when the local-part text changes.
  public var onLocalPartChanged: ((String) -> Void)?
  /// Called when the user taps the suffix control.
  public var onSuffixTap: (() -> Void)?

  private let localField = FKTextField(inputRule: FKTextFieldInputRule(formatType: .email))
  private let suffixButton = UIButton(type: .system)
  private let rowStack = UIStackView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellEmailSuffixConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellEmailSuffixConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    localField.text = configuration.localPart
    localField.placeholder = configuration.placeholder
    suffixButton.setTitle(configuration.selectedSuffix, for: .normal)
    localField.isEnabled = configuration.isEnabled
    suffixButton.isEnabled = configuration.isEnabled
    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellEmailSuffixRow) {
    apply(viewModel.configuration)
    localField.text = viewModel.text
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onLocalPartChanged = nil
    onSuffixTap = nil
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rowStack.axis = .horizontal
    rowStack.spacing = 8
    rowStack.alignment = .center
    rowStack.translatesAutoresizingMaskIntoConstraints = false

    suffixButton.setContentHuggingPriority(.required, for: .horizontal)
    suffixButton.addTarget(self, action: #selector(suffixTapped), for: .touchUpInside)

    rowStack.addArrangedSubview(localField)
    rowStack.addArrangedSubview(suffixButton)
    contentView.addSubview(rowStack)

    NSLayoutConstraint.activate([
      rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      rowStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])

    localField.onEditingChanged = { [weak self] raw, _ in
      self?.onLocalPartChanged?(raw)
    }
  }

  @objc private func suffixTapped() {
    onSuffixTap?()
  }
}
