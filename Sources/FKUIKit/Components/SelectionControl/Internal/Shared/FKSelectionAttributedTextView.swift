import UIKit

/// Non-editable attributed title renderer used for measuring and link hit-testing.
///
/// User interaction is disabled; the owning ``FKCheckbox`` / ``FKRadioButton`` routes taps
/// so non-link text toggles while link glyphs fire ``onLinkActivated``.
@MainActor
final class FKSelectionAttributedTextView: UITextView {
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    isEditable = false
    isScrollEnabled = false
    isSelectable = false
    isUserInteractionEnabled = false
    textContainerInset = .zero
    textContainer.lineFragmentPadding = 0
    linkTextAttributes = [
      .foregroundColor: UIColor.link,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
  }

  override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    return CGSize(width: UIView.noIntrinsicMetric, height: ceil(size.height))
  }

  /// Returns the link URL under `point` in this view’s coordinates, if any.
  func linkURL(at point: CGPoint) -> URL? {
    guard attributedText.length > 0 else { return nil }
    let layoutManager = self.layoutManager
    let textContainer = self.textContainer
    var fraction: CGFloat = 0
    let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer, fractionOfDistanceThroughGlyph: &fraction)
    guard glyphIndex < layoutManager.numberOfGlyphs else { return nil }
    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    guard charIndex < attributedText.length else { return nil }
    let attrs = attributedText.attributes(at: charIndex, effectiveRange: nil)
    if let url = attrs[.link] as? URL {
      return url
    }
    if let string = attrs[.link] as? String {
      return URL(string: string)
    }
    return nil
  }
}
