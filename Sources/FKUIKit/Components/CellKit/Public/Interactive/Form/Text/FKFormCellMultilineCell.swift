import FKCoreKit
import UIKit

/// ``FKCountTextView`` multiline field in form chrome (F-04).
@MainActor
public final class FKFormCellMultilineCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormMultilineRow

  /// Called when the text changes.
  public var onTextChanged: ((String) -> Void)?

  private let chromeView = FKFormFieldChromeView()
  private let textView = FKCountTextView(configuration: FKCountTextView.Configuration())
  private var storedConfiguration = FKFormCellMultilineConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellMultilineConfiguration) {
    apply(configuration, appearance: .default, text: textView.text)
  }

  public func apply(
    _ configuration: FKFormCellMultilineConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    text: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    textView.countConfiguration = FKCountTextView.Configuration(
      maxLength: configuration.maxLength,
      showsCounter: configuration.showsCounter,
      placeholder: configuration.placeholder
    )
    textView.text = text
    textView.isEditable = configuration.isEnabled
    textView.isUserInteractionEnabled = configuration.isEnabled

    installTextView()
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      leadingAccessory: .none,
      trailingAccessory: .none,
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: textView.isFirstResponder
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormMultilineRow) {
    apply(viewModel.configuration, text: viewModel.text)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    textView.text = ""
    textView.onTextChanged = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wireTextViewCallbacks()
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

    installTextView()
    wireTextViewCallbacks()
  }

  private func installTextView() {
    chromeView.textFieldHost.subviews.forEach { $0.removeFromSuperview() }
    textView.translatesAutoresizingMaskIntoConstraints = false
    chromeView.textFieldHost.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: chromeView.textFieldHost.topAnchor),
      textView.leadingAnchor.constraint(equalTo: chromeView.textFieldHost.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: chromeView.textFieldHost.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: chromeView.textFieldHost.bottomAnchor),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
    ])
  }

  private func wireTextViewCallbacks() {
    textView.onTextChanged = { [weak self] text in
      self?.onTextChanged?(text)
    }
  }
}
