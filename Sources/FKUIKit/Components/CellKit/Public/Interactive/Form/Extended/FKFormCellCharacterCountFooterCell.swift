import FKCoreKit
import UIKit

/// Multiline input with a trailing character count footer (X-69).
@MainActor
public final class FKFormCellCharacterCountFooterCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellCharacterCountFooterRow

  public var onTextChanged: ((String) -> Void)?

  private let chromeView = FKFormFieldChromeView()
  private let textView = FKCountTextView(configuration: FKCountTextView.Configuration())
  private let footerLabel = UILabel()
  private var storedMaxLength = 280

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellCharacterCountFooterConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellCharacterCountFooterConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    storedMaxLength = configuration.maxLength
    textView.countConfiguration = FKCountTextView.Configuration(
      maxLength: configuration.maxLength,
      showsCounter: false,
      placeholder: configuration.placeholder
    )
    textView.text = configuration.text
    textView.isEditable = configuration.isEnabled
    updateFooter(count: configuration.text.count)

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
  }

  public func configure(with viewModel: FKFormCellCharacterCountFooterRow) {
    var configuration = viewModel.configuration
    configuration.text = viewModel.text
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    textView.text = ""
    chromeView.reset()
    selectionStyle = .none
    wireCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    footerLabel.font = .preferredFont(forTextStyle: .caption1)
    footerLabel.textColor = .secondaryLabel
    footerLabel.textAlignment = .right
    footerLabel.translatesAutoresizingMaskIntoConstraints = false

    chromeView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chromeView)
    contentView.addSubview(footerLabel)
    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: contentView.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      footerLabel.topAnchor.constraint(equalTo: chromeView.bottomAnchor, constant: 4),
      footerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      footerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
    wireCallbacks()
  }

  private func wireCallbacks() {
    textView.onTextChanged = { [weak self] text in
      self?.updateFooter(count: text.count)
      self?.onTextChanged?(text)
    }
  }

  private func updateFooter(count: Int) {
    let remaining = max(0, storedMaxLength - count)
    footerLabel.text = "\(count)/\(storedMaxLength) · \(remaining) remaining"
    footerLabel.textColor = remaining == 0 ? .systemRed : .secondaryLabel
  }
}
