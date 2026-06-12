import FKCoreKit
import UIKit

/// Configurable text input form row supporting all primary form layouts (X-01–X-05).
@MainActor
public final class FKFormCellTextFieldCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormTextFieldRow

  /// Called on the main actor when the embedded field text changes.
  public var onTextChanged: ((String) -> Void)?

  private let chromeView = FKFormFieldChromeView()
  private let textField = FKTextField(configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(
      formatType: .alphaNumeric,
      allowsWhitespace: true,
      allowsSpecialCharacters: true
    ),
    style: FKTextFieldManager.shared.defaultStyle
  ))
  private var storedConfiguration = FKFormCellTextFieldConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a form text field configuration with default appearance.
  public func apply(_ configuration: FKFormCellTextFieldConfiguration) {
    apply(configuration, appearance: .default, text: textField.rawText)
  }

  /// Applies a form text field configuration with explicit appearance and text value.
  public func apply(
    _ configuration: FKFormCellTextFieldConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    text: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    var embeddedConfiguration = FKFormTextFieldEmbedding.prepare(
      configuration.textFieldConfiguration,
      trailingAccessory: configuration.trailingAccessory
    )
    if let placeholder = configuration.placeholder {
      embeddedConfiguration.placeholder = placeholder
    }
    textField.configure(embeddedConfiguration)
    textField.isEnabled = configuration.isEnabled
    textField.text = text

    chromeView.install(textField: textField)
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      leadingAccessory: configuration.leadingAccessory,
      trailingAccessory: configuration.trailingAccessory,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: textField.isFirstResponder
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormTextFieldRow) {
    apply(viewModel.configuration, text: viewModel.text)
  }

  public func configure(with viewModel: FKFormPasswordRow) {
    apply(viewModel.configuration, text: viewModel.text)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    textField.onEditingChanged = nil
    textField.onDidBeginEditing = nil
    textField.onDidEndEditing = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wireTextFieldCallbacks()
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

    chromeView.install(textField: textField)
    wireTextFieldCallbacks()
  }

  private func wireTextFieldCallbacks() {
    textField.onEditingChanged = { [weak self] (raw: String, _: String) in
      guard let self else { return }
      self.onTextChanged?(raw)
    }
    textField.onDidBeginEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        validation: self.storedConfiguration.validation,
        leadingAccessory: self.storedConfiguration.leadingAccessory,
        trailingAccessory: self.storedConfiguration.trailingAccessory,
        appearance: self.appearance,
        focusState: .focused,
        isFieldFocused: true
      )
    }
    textField.onDidEndEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        validation: self.storedConfiguration.validation,
        leadingAccessory: self.storedConfiguration.leadingAccessory,
        trailingAccessory: self.storedConfiguration.trailingAccessory,
        appearance: self.appearance,
        focusState: self.storedConfiguration.isEnabled ? .unfocused : .disabled,
        isFieldFocused: false
      )
    }
  }
}
