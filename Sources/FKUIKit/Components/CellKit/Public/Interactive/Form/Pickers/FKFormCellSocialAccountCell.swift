import FKCoreKit
import UIKit

/// Split platform picker and username form row (X-07).
@MainActor
public final class FKFormCellSocialAccountCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormSocialAccountRow

  /// Called when the user taps the platform picker zone.
  public var onPlatformTap: (() -> Void)?
  /// Called when the username text changes.
  public var onUsernameChanged: ((String) -> Void)?

  private let chromeView = FKFormSocialAccountChromeView()
  private let usernameField = FKTextField(configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: false, allowsSpecialCharacters: true),
    style: FKTextFieldManager.shared.defaultStyle
  ))
  private var storedConfiguration = FKFormCellSocialAccountConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellSocialAccountConfiguration) {
    apply(configuration, appearance: .default, username: usernameField.rawText)
  }

  public func apply(
    _ configuration: FKFormCellSocialAccountConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    username: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    var embeddedConfiguration = FKFormTextFieldEmbedding.prepare(
      FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: false, allowsSpecialCharacters: true),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: configuration.placeholder
      ),
      trailingAccessory: .none
    )
    if let placeholder = configuration.placeholder {
      embeddedConfiguration.placeholder = placeholder
    }
    usernameField.configure(embeddedConfiguration)
    usernameField.isEnabled = configuration.isEnabled
    usernameField.text = username

    chromeView.install(usernameField: usernameField)
    chromeView.onPlatformPickerTapped = { [weak self] in
      self?.onPlatformTap?()
    }
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      platformPicker: configuration.platformPicker,
      validation: configuration.validation,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: usernameField.isFirstResponder,
      isEnabled: configuration.isEnabled
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormSocialAccountRow) {
    apply(viewModel.configuration, username: viewModel.username)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onPlatformTap = nil
    onUsernameChanged = nil
    usernameField.onEditingChanged = nil
    usernameField.onDidBeginEditing = nil
    usernameField.onDidEndEditing = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wireUsernameFieldCallbacks()
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

    chromeView.install(usernameField: usernameField)
    wireUsernameFieldCallbacks()
  }

  private func wireUsernameFieldCallbacks() {
    usernameField.onEditingChanged = { [weak self] (raw: String, _: String) in
      self?.onUsernameChanged?(raw)
    }
    usernameField.onDidBeginEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        platformPicker: self.storedConfiguration.platformPicker,
        validation: self.storedConfiguration.validation,
        appearance: self.appearance,
        focusState: .focused,
        isFieldFocused: true,
        isEnabled: self.storedConfiguration.isEnabled
      )
    }
    usernameField.onDidEndEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        platformPicker: self.storedConfiguration.platformPicker,
        validation: self.storedConfiguration.validation,
        appearance: self.appearance,
        focusState: self.storedConfiguration.isEnabled ? .unfocused : .disabled,
        isFieldFocused: false,
        isEnabled: self.storedConfiguration.isEnabled
      )
    }
  }
}
