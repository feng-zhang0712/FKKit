import UIKit

/// Non-editable attributed text view with tappable link ranges for CellKit rich rows.
@MainActor
final class FKCellLinkTextView: UIView {
  var onLinkTapped: ((FKCellLinkRange) -> Void)?

  private let textView = UITextView()
  private var activeLinkRanges: [FKCellLinkRange] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func resetForReuse() {
    onLinkTapped = nil
    textView.attributedText = nil
    activeLinkRanges = []
  }

  func apply(
    text: String,
    linkRanges: [FKCellLinkRange],
    font: UIFont,
    textColor: UIColor,
    linkColor: UIColor,
    alignment: NSTextAlignment = .natural
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment

    let attributed = NSMutableAttributedString(
      string: text,
      attributes: [
        .font: font,
        .foregroundColor: textColor,
        .paragraphStyle: paragraph,
      ]
    )
    applyAttributedBody(attributed, linkRanges: linkRanges, linkColor: linkColor)
  }

  func applyAttributedBody(
    _ body: NSAttributedString,
    linkRanges: [FKCellLinkRange],
    linkColor: UIColor
  ) {
    let mutable = NSMutableAttributedString(attributedString: body)
    activeLinkRanges = linkRanges
    for link in linkRanges {
      let range = link.nsRange
      guard NSMaxRange(range) <= mutable.length else { continue }
      mutable.addAttributes(
        [
          .foregroundColor: linkColor,
          .underlineStyle: NSUnderlineStyle.single.rawValue,
        ],
        range: range
      )
      if let url = link.url {
        mutable.addAttribute(.link, value: url, range: range)
      }
    }

    textView.attributedText = mutable
    textView.linkTextAttributes = [
      .foregroundColor: linkColor,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    accessibilityLabel = mutable.string
  }

  private func commonInit() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.adjustsFontForContentSizeCategory = true
    textView.delegate = self
    addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: topAnchor),
      textView.leadingAnchor.constraint(equalTo: leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}

extension FKCellLinkTextView: UITextViewDelegate {
  func textView(
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

  func textViewDidChangeSelection(_ textView: UITextView) {
    textView.selectedTextRange = nil
  }
}
