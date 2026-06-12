import FKCoreKit
import UIKit

/// Agreement checkbox row with tappable link ranges (X-52, F-05).
@MainActor
public final class FKFormCellAgreementCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormAgreementRow

  /// Called on the main actor when the user toggles the checkbox.
  public var onCheckedChanged: ((Bool) -> Void)?

  /// Called when the user taps a configured link range.
  public var onLinkTapped: ((FKCellLinkRange) -> Void)?

  private let checkboxButton = UIButton(type: .system)
  private let textView = UITextView()
  private var activeLinkRanges: [FKCellLinkRange] = []
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an agreement row configuration.
  public func apply(_ configuration: FKFormCellAgreementConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies an agreement row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKFormCellAgreementConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.appearance = appearance
    checkboxButton.isSelected = configuration.isChecked
    checkboxButton.isEnabled = configuration.isEnabled
    isUserInteractionEnabled = configuration.isEnabled

    let font = appearance.subtitleTextStyle.resolvedFont(compatibleWith: traitCollection)
    let bodyColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)
    let linkColor = appearance.linkColor.resolvedColor(with: traitCollection)

    let attributed = NSMutableAttributedString(
      string: configuration.text,
      attributes: [
        .font: font,
        .foregroundColor: bodyColor,
      ]
    )

    activeLinkRanges = configuration.linkRanges
    for link in configuration.linkRanges {
      let range = link.nsRange
      guard NSMaxRange(range) <= attributed.length else { continue }
      attributed.addAttributes(
        [
          .foregroundColor: linkColor,
          .underlineStyle: NSUnderlineStyle.single.rawValue,
        ],
        range: range
      )
      if let url = link.url {
        attributed.addAttribute(.link, value: url, range: range)
      }
    }

    textView.attributedText = attributed
    textView.linkTextAttributes = [
      .foregroundColor: linkColor,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]

    selectionStyle = .none
    accessibilityLabel = configuration.text
    accessibilityTraits = configuration.isChecked ? [.selected, .button] : [.button]
  }

  public func configure(with viewModel: FKFormAgreementRow) {
    var configuration = viewModel.configuration
    configuration.isChecked = viewModel.isChecked
    apply(configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onCheckedChanged = nil
    onLinkTapped = nil
    textView.attributedText = nil
    activeLinkRanges = []
    checkboxButton.isSelected = false
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    checkboxButton.translatesAutoresizingMaskIntoConstraints = false
    checkboxButton.setImage(UIImage(systemName: "square"), for: .normal)
    checkboxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
    checkboxButton.tintColor = .systemBlue
    checkboxButton.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.adjustsFontForContentSizeCategory = true
    textView.delegate = self

    contentView.addSubview(checkboxButton)
    contentView.addSubview(textView)

    NSLayoutConstraint.activate([
      checkboxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      checkboxButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      checkboxButton.widthAnchor.constraint(equalToConstant: 28),
      checkboxButton.heightAnchor.constraint(equalToConstant: 28),

      textView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 8),
      textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  @objc private func toggleCheckbox() {
    checkboxButton.isSelected.toggle()
    onCheckedChanged?(checkboxButton.isSelected)
  }
}

extension FKFormCellAgreementCell: UITextViewDelegate {
  public func textView(
    _ textView: UITextView,
    shouldInteractWith URL: URL,
    in characterRange: NSRange,
    interaction: UITextItemInteraction
  ) -> Bool {
    if let link = activeLinkRanges.first(where: { $0.nsRange == characterRange }) {
      onLinkTapped?(link)
      return false
    }
    return true
  }

  public func textViewDidChangeSelection(_ textView: UITextView) {
    textView.selectedTextRange = nil
  }
}
