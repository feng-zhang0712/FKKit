import UIKit

/// Configuration for ``FKCellSectionFooterView``.
public struct FKCellSectionFooterConfiguration: Sendable, Equatable {
  public var text: String
  public var linkRanges: [FKCellLinkRange]

  /// Creates a section footer configuration.
  public init(text: String, linkRanges: [FKCellLinkRange] = []) {
    self.text = text
    self.linkRanges = linkRanges
  }
}

/// Settings-style section footer with optional tappable link ranges (S-02).
@MainActor
public final class FKCellSectionFooterView: UITableViewHeaderFooterView {
  public static var reuseIdentifier: String { String(describing: Self.self) }

  /// Invoked when the user taps a configured link range.
  public var onLinkTapped: ((FKCellLinkRange) -> Void)?

  private let textView = UITextView()
  private var configuration = FKCellSectionFooterConfiguration(text: "")
  private var appearance: FKCellAppearanceConfiguration = .default
  private var activeLinkRanges: [FKCellLinkRange] = []

  public override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies footer copy, link ranges, and optional appearance overrides.
  public func apply(
    _ configuration: FKCellSectionFooterConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    self.configuration = configuration
    self.appearance = appearance
    refreshContent()
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onLinkTapped = nil
    textView.attributedText = nil
    activeLinkRanges = []
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      refreshContent()
    }
  }

  private func commonInit() {
    contentView.backgroundColor = .clear
    backgroundView = UIView()
    backgroundView?.backgroundColor = .clear

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.adjustsFontForContentSizeCategory = true
    textView.delegate = self
    contentView.addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(
        equalTo: contentView.topAnchor,
        constant: FKCellLayoutMetrics.sectionFooterTopInset
      ),
      textView.leadingAnchor.constraint(
        equalTo: contentView.layoutMarginsGuide.leadingAnchor,
        constant: FKCellLayoutMetrics.horizontalContentInset
      ),
      textView.trailingAnchor.constraint(
        equalTo: contentView.layoutMarginsGuide.trailingAnchor,
        constant: -FKCellLayoutMetrics.horizontalContentInset
      ),
      textView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -FKCellLayoutMetrics.sectionFooterBottomInset
      ),
    ])
  }

  private func refreshContent() {
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
    accessibilityLabel = configuration.text
  }
}

extension FKCellSectionFooterView: UITextViewDelegate {
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
