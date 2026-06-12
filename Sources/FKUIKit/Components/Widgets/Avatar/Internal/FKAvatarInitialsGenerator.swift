import CryptoKit
import FKCoreKit
import UIKit

enum FKAvatarInitialsGenerator {
  /// Generates 1–2 uppercase initials from a display name (Latin words or first CJK grapheme cluster).
  static func initials(from displayName: String) -> String {
    let cleaned = displayName.fk_trimmed.fk_removingSpecialCharacters
    guard !cleaned.fk_isBlank else { return "" }

    if containsCJK(in: cleaned) {
      return cleaned.fk_limitedPrefix(1)
    }

    let words = cleaned.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    guard !words.isEmpty else { return "" }

    if words.count == 1 {
      let word = words[0]
      let letters = word.filter(\.isLetter)
      if letters.count >= 2 {
        return String(letters.prefix(2)).uppercased()
      }
      return String(word.prefix(2)).uppercased()
    }

    let firstLetters = words.prefix(2).compactMap { word -> String? in
      guard let char = word.first(where: \.isLetter) ?? word.first else { return nil }
      return String(char).uppercased()
    }
    return firstLetters.joined()
  }

  /// Stable background color derived from the display name hash.
  static func backgroundColor(for displayName: String) -> UIColor {
    let digest = Insecure.MD5.hash(data: displayName.fk_utf8Data)
    let value = digest.withUnsafeBytes { raw -> UInt32 in
      raw.load(as: UInt32.self)
    }
    let hue = CGFloat(value % 360) / 360
    return UIColor(hue: hue, saturation: 0.45, brightness: 0.65, alpha: 1)
  }

  /// Scales initials font to fit the avatar diameter.
  static func scaledFont(base: UIFont, avatarDiameter: CGFloat) -> UIFont {
    let scale = avatarDiameter / 40
    let size = max(10, base.pointSize * scale)
    return base.withSize(size)
  }

  private static func containsCJK(in text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
      (0x4E00 ... 0x9FFF).contains(scalar.value)
        || (0x3400 ... 0x4DBF).contains(scalar.value)
    }
  }
}
