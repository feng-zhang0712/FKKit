import FKCoreKit
import UIKit

/// Biometric authentication trigger row using ``FKBiometricAuth`` (X-60).
@MainActor
public final class FKFormCellBiometricCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellBiometricRow

  /// Called after a successful biometric authentication.
  public var onAuthenticated: (() -> Void)?

  private let titleLabel = UILabel()
  private let authButton = FKButton()
  private let errorLabel = UILabel()
  private let stack = UIStackView()
  private var storedConfiguration = FKFormCellBiometricConfiguration()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellBiometricConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellBiometricConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    storedConfiguration = configuration
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    authButton.setTitle(FKButtonLabelConfiguration(text: configuration.buttonTitle), for: .normal)
    authButton.isEnabled = configuration.isEnabled

    if let error = configuration.errorText, !error.isEmpty {
      errorLabel.text = error
      errorLabel.isHidden = false
    } else {
      errorLabel.isHidden = true
    }

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellBiometricRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onAuthenticated = nil
    errorLabel.text = nil
    errorLabel.isHidden = true
    selectionStyle = .none
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    errorLabel.font = .preferredFont(forTextStyle: .footnote)
    errorLabel.textColor = .systemRed
    errorLabel.numberOfLines = 0
    errorLabel.isHidden = true

    authButton.addTarget(self, action: #selector(authenticateTapped), for: .touchUpInside)

    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(authButton)
    stack.addArrangedSubview(errorLabel)
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      authButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }

  @objc private func authenticateTapped() {
    guard storedConfiguration.isEnabled else { return }
    Task { @MainActor in
      do {
        try await FKBiometricAuth.shared.authenticate(reason: storedConfiguration.authReason)
        onAuthenticated?()
      } catch {
        errorLabel.text = error.localizedDescription
        errorLabel.isHidden = false
      }
    }
  }
}
