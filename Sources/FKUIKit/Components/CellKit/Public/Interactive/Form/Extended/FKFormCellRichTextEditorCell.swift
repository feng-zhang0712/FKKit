import FKCoreKit
import UIKit

/// Compact formatting toolbar above a multiline editor (X-58).
@MainActor
public final class FKFormCellRichTextEditorCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCellRichTextEditorRow

  public var onTextChanged: ((String) -> Void)?
  public var onBoldTap: (() -> Void)?
  public var onItalicTap: (() -> Void)?
  public var onLinkTap: (() -> Void)?

  private let titleLabel = UILabel()
  private let toolbar = UIStackView()
  private let textView = FKCountTextView(configuration: FKCountTextView.Configuration())

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellRichTextEditorConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellRichTextEditorConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    titleLabel.text = configuration.label
    titleLabel.isHidden = configuration.label == nil
    textView.countConfiguration = FKCountTextView.Configuration(
      maxLength: configuration.maxLength,
      showsCounter: true,
      placeholder: configuration.placeholder
    )
    textView.text = configuration.text
    textView.isEditable = configuration.isEnabled

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCellRichTextEditorRow) {
    apply(viewModel.configuration)
    textView.text = viewModel.text
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onTextChanged = nil
    onBoldTap = nil
    onItalicTap = nil
    onLinkTap = nil
    textView.text = ""
    selectionStyle = .none
    wireCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = .preferredFont(forTextStyle: .footnote)
    titleLabel.textColor = .secondaryLabel

    toolbar.axis = .horizontal
    toolbar.spacing = 8
    toolbar.distribution = .fillEqually
    toolbar.translatesAutoresizingMaskIntoConstraints = false

    let bold = makeToolbarButton(title: "B", action: #selector(boldTapped))
    bold.titleLabel?.font = .boldSystemFont(ofSize: 17)
    let italic = makeToolbarButton(title: "I", action: #selector(italicTapped))
    italic.titleLabel?.font = .italicSystemFont(ofSize: 17)
    let link = makeToolbarButton(title: "Link", action: #selector(linkTapped))
    toolbar.addArrangedSubview(bold)
    toolbar.addArrangedSubview(italic)
    toolbar.addArrangedSubview(link)

    textView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(titleLabel)
    contentView.addSubview(toolbar)
    contentView.addSubview(textView)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      toolbar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      toolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      toolbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      toolbar.heightAnchor.constraint(equalToConstant: 36),
      textView.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
      textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
    ])
    wireCallbacks()
  }

  private func makeToolbarButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.layer.cornerRadius = 6
    button.layer.borderWidth = 1
    button.layer.borderColor = UIColor.separator.cgColor
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func wireCallbacks() {
    textView.onTextChanged = { [weak self] text in self?.onTextChanged?(text) }
  }

  @objc private func boldTapped() { onBoldTap?() }
  @objc private func italicTapped() { onItalicTap?() }
  @objc private func linkTapped() { onLinkTap?() }
}
