import FKCoreKit
import UIKit

enum FKMarqueeTextMeasurement {
  static func singleLineWidth(for text: String, font: UIFont) -> CGFloat {
    guard !text.isEmpty else { return 0 }
    let rect = (text as NSString).boundingRect(
      with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return ceil(rect.width)
  }

  /// Uses ``UILabel/fk_numberOfLinesThatFit()`` to confirm the label fits on one line at the given width.
  static func fitsSingleLine(text: String, font: UIFont, width: CGFloat) -> Bool {
    guard width > 0, !text.isEmpty else { return true }
    let probe = UILabel()
    probe.font = font
    probe.text = text
    probe.numberOfLines = 0
    probe.preferredMaxLayoutWidth = width
    probe.bounds = CGRect(x: 0, y: 0, width: width, height: font.lineHeight * 4)
    return probe.fk_numberOfLinesThatFit() <= 1
      && singleLineWidth(for: text, font: font) <= width + 0.5
  }
}
