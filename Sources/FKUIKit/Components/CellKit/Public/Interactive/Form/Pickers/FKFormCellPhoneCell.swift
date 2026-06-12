import FKCoreKit
import UIKit

/// Split country-code and phone-number form row (X-06, F-12).
@MainActor
public final class FKFormCellPhoneCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormPhoneRow

  /// Called on the main actor when the user taps the country-code zone.
  public var onCountryTap: (() -> Void)?
  /// Called on the main actor when the phone number text changes.
  public var onPhoneNumberChanged: ((String) -> Void)?

  private let chromeView = FKFormPhoneChromeView()
  private let phoneField = FKTextField(configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(formatType: .phoneNumber),
    style: FKTextFieldManager.shared.defaultStyle
  ))
  private var storedConfiguration = FKFormCellPhoneConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a phone field configuration with default appearance.
  public func apply(_ configuration: FKFormCellPhoneConfiguration) {
    apply(configuration, appearance: .default, phoneNumber: phoneField.rawText)
  }

  /// Applies a phone field configuration with explicit appearance and phone number.
  public func apply(
    _ configuration: FKFormCellPhoneConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    phoneNumber: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    var embeddedConfiguration = FKFormTextFieldEmbedding.prepare(
      FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(formatType: .phoneNumber),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: configuration.placeholder
      ),
      trailingAccessory: .none
    )
    if let placeholder = configuration.placeholder {
      embeddedConfiguration.placeholder = placeholder
    }
    phoneField.configure(embeddedConfiguration)
    phoneField.isEnabled = configuration.isEnabled
    phoneField.text = phoneNumber

    chromeView.install(phoneField: phoneField)
    chromeView.onCountryPickerTapped = { [weak self] in
      self?.onCountryTap?()
    }
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      countryPicker: configuration.countryPicker,
      validation: configuration.validation,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: phoneField.isFirstResponder,
      isEnabled: configuration.isEnabled
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormPhoneRow) {
    apply(viewModel.configuration, phoneNumber: viewModel.phoneNumber)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onCountryTap = nil
    onPhoneNumberChanged = nil
    phoneField.onEditingChanged = nil
    phoneField.onDidBeginEditing = nil
    phoneField.onDidEndEditing = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wirePhoneFieldCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    chromeView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chromeView)
    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: contentView.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      chromeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    chromeView.install(phoneField: phoneField)
    wirePhoneFieldCallbacks()
  }

  private func wirePhoneFieldCallbacks() {
    phoneField.onEditingChanged = { [weak self] (raw: String, _: String) in
      guard let self else { return }
      self.onPhoneNumberChanged?(raw)
    }
    phoneField.onDidBeginEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        countryPicker: self.storedConfiguration.countryPicker,
        validation: self.storedConfiguration.validation,
        appearance: self.appearance,
        focusState: .focused,
        isFieldFocused: true,
        isEnabled: self.storedConfiguration.isEnabled
      )
    }
    phoneField.onDidEndEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        countryPicker: self.storedConfiguration.countryPicker,
        validation: self.storedConfiguration.validation,
        appearance: self.appearance,
        focusState: self.storedConfiguration.isEnabled ? .unfocused : .disabled,
        isFieldFocused: false,
        isEnabled: self.storedConfiguration.isEnabled
      )
    }
  }
}
