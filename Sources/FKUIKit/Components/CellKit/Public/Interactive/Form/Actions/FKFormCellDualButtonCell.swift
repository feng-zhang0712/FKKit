import FKCoreKit
import UIKit

/// Dual ``FKButton`` CTA row (X-50).
@MainActor
public final class FKFormCellDualButtonCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormDualButtonRow

  /// Called when the user taps the primary button.
  public var onPrimaryTap: (() -> Void)?
  /// Called when the user taps the secondary button.
  public var onSecondaryTap: (() -> Void)?

  private let buttonStack = UIStackView()
  private let primaryButton = FKButton()
  private let secondaryButton = FKButton()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellDualButtonConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellDualButtonConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    primaryButton.setTitle(
      FKButtonLabelConfiguration(text: configuration.primaryTitle, font: .boldSystemFont(ofSize: 17), color: .white),
      for: .normal
    )
    secondaryButton.setTitle(
      FKButtonLabelConfiguration(text: configuration.secondaryTitle, font: .systemFont(ofSize: 17), color: .systemBlue),
      for: .normal
    )

    primaryButton.isEnabled = configuration.isPrimaryEnabled && !configuration.isPrimaryLoading
    secondaryButton.isEnabled = configuration.isSecondaryEnabled && !configuration.isSecondaryLoading
    primaryButton.setLoading(configuration.isPrimaryLoading)
    secondaryButton.setLoading(configuration.isSecondaryLoading)

    buttonStack.axis = configuration.layout == .horizontal ? .horizontal : .vertical
    buttonStack.distribution = .fillEqually

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = "\(configuration.primaryTitle), \(configuration.secondaryTitle)"
  }

  public func configure(with viewModel: FKFormDualButtonRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onPrimaryTap = nil
    onSecondaryTap = nil
    primaryButton.setLoading(false)
    secondaryButton.setLoading(false)
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    buttonStack.spacing = 12
    buttonStack.translatesAutoresizingMaskIntoConstraints = false

    primaryButton.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)
    secondaryButton.addTarget(self, action: #selector(handleSecondaryTap), for: .touchUpInside)

    buttonStack.addArrangedSubview(primaryButton)
    buttonStack.addArrangedSubview(secondaryButton)

    contentView.addSubview(buttonStack)
    NSLayoutConstraint.activate([
      buttonStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      secondaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  @objc private func handlePrimaryTap() {
    onPrimaryTap?()
  }

  @objc private func handleSecondaryTap() {
    onSecondaryTap?()
  }
}
