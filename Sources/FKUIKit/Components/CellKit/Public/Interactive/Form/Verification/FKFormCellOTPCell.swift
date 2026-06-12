import FKCoreKit
import UIKit

/// OTP slot input form row embedding ``FKCodeTextField`` (X-18, F-03).
@MainActor
public final class FKFormCellOTPCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormOTPRow

  /// Called on the main actor when the OTP code changes.
  public var onCodeChanged: ((String) -> Void)?
  /// Called on the main actor when the OTP code reaches the configured length.
  public var onCodeCompleted: ((String) -> Void)?

  private let rootStack = UIStackView()
  private let topLabel = UILabel()
  private let codeField = FKCodeTextField()
  private let messageLabel = UILabel()
  private var storedConfiguration = FKFormCellOTPConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an OTP configuration with default appearance.
  public func apply(_ configuration: FKFormCellOTPConfiguration) {
    apply(configuration, appearance: .default, code: codeField.code)
  }

  /// Applies an OTP configuration with explicit appearance and code value.
  public func apply(
    _ configuration: FKFormCellOTPConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    code: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    codeField.codeConfiguration = configuration.codeConfiguration
    codeField.isEnabled = configuration.isEnabled
    if !code.isEmpty {
      codeField.text = code.filter(\.isNumber)
    } else {
      codeField.clearCode()
    }

    applyLabel(configuration.label, validation: configuration.validation, appearance: appearance)
    applyValidationMessage(configuration.validation, appearance: appearance)

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormOTPRow) {
    apply(viewModel.configuration, code: viewModel.code)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onCodeChanged = nil
    onCodeCompleted = nil
    codeField.onCodeChanged = nil
    codeField.onCodeCompleted = nil
    codeField.clearCode()
    topLabel.text = nil
    messageLabel.text = nil
    messageLabel.isHidden = true
    selectionStyle = .none
    accessibilityLabel = nil
    wireCodeFieldCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    rootStack.axis = .vertical
    rootStack.spacing = FKFormLayoutMetrics.labelFieldSpacing
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    topLabel.numberOfLines = 0
    topLabel.adjustsFontForContentSizeCategory = true
    topLabel.font = .preferredFont(forTextStyle: .footnote)
    topLabel.textColor = .secondaryLabel
    topLabel.isHidden = true

    codeField.translatesAutoresizingMaskIntoConstraints = false

    messageLabel.numberOfLines = 0
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.isHidden = true

    rootStack.addArrangedSubview(topLabel)
    rootStack.addArrangedSubview(codeField)
    rootStack.addArrangedSubview(messageLabel)

    contentView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      codeField.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])

    wireCodeFieldCallbacks()
  }

  private func wireCodeFieldCallbacks() {
    codeField.onCodeChanged = { [weak self] code in
      self?.onCodeChanged?(code)
    }
    codeField.onCodeCompleted = { [weak self] code in
      self?.onCodeCompleted?(code)
    }
  }

  private func applyLabel(
    _ label: String?,
    validation: FKFormFieldValidationPresentation,
    appearance: FKCellAppearanceConfiguration
  ) {
    let requiredSuffix = validation.isRequired && validation.showsRequiredIndicator
    if let label, !label.isEmpty {
      topLabel.text = requiredSuffix ? label + " *" : label
      topLabel.textColor = requiredSuffix ? appearance.destructiveColor : .secondaryLabel
      topLabel.isHidden = false
    } else {
      topLabel.isHidden = true
      topLabel.text = nil
    }
  }

  private func applyValidationMessage(
    _ validation: FKFormFieldValidationPresentation,
    appearance: FKCellAppearanceConfiguration
  ) {
    if let error = validation.errorText, !error.isEmpty {
      messageLabel.isHidden = false
      messageLabel.text = error
      messageLabel.textColor = appearance.destructiveColor
      codeField.setErrorState(true, shakes: false)
    } else if let success = validation.successText, !success.isEmpty {
      messageLabel.isHidden = false
      messageLabel.text = success
      messageLabel.textColor = .systemGreen
      codeField.setErrorState(false, shakes: false)
    } else if let helper = validation.helperText, !helper.isEmpty {
      messageLabel.isHidden = false
      messageLabel.text = helper
      messageLabel.textColor = appearance.secondaryLabelColor
      codeField.setErrorState(false, shakes: false)
    } else {
      messageLabel.isHidden = true
      messageLabel.text = nil
      codeField.setErrorState(false, shakes: false)
    }
  }
}
