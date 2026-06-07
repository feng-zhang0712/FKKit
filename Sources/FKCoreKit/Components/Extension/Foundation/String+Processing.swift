import Foundation

// MARK: - Text processing

public extension String {
  /// Removes all whitespace and newline characters.
  var fk_removingAllWhitespace: String {
    replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
  }

  /// Removes special characters but keeps letters, numbers, and spaces.
  var fk_removingSpecialCharacters: String {
    replacingOccurrences(of: #"[^A-Za-z0-9\u4e00-\u9fa5\s]"#, with: "", options: .regularExpression)
  }

  /// Masks digits as `138****5678` when at least seven digits are present.
  func fk_maskedPhone() -> String {
    let digits = filter(\.isNumber)
    guard digits.count >= 7 else { return self }
    return "\(digits.prefix(3))****\(digits.suffix(4))"
  }

  /// Masks an ID card, keeping the first and last four characters.
  func fk_maskedIDCard() -> String {
    guard count > 8 else { return self }
    return "\(prefix(4))\(String(repeating: "*", count: count - 8))\(suffix(4))"
  }

  /// Masks the local part of an email address.
  func fk_maskedEmail() -> String {
    let parts = split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return self }
    let name = String(parts[0])
    let domain = String(parts[1])
    guard !name.isEmpty else { return self }
    let masked = name.count <= 2
      ? "\(name.prefix(1))*"
      : "\(name.prefix(1))\(String(repeating: "*", count: name.count - 2))\(name.suffix(1))"
    return "\(masked)@\(domain)"
  }

  /// Masks a bank card number, keeping the first and last four digits.
  func fk_maskedBankCard() -> String {
    let digits = filter(\.isNumber)
    guard digits.count > 8 else { return self }
    return "\(digits.prefix(4)) \(String(repeating: "*", count: max(0, digits.count - 8))) \(digits.suffix(4))"
  }

  /// Converts Chinese text to lowercase pinyin.
  func fk_pinyin(dropDiacritics: Bool = true) -> String {
    let mutable = NSMutableString(string: self) as CFMutableString
    CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
    if dropDiacritics {
      CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
    }
    return (mutable as String).lowercased()
  }

  /// Returns the uppercase pinyin first letter, or `"#"` when unavailable.
  var fk_pinyinFirstLetter: String {
    guard let first = fk_pinyin().first else { return "#" }
    let letter = String(first).uppercased()
    return letter.range(of: "[A-Z]", options: .regularExpression) != nil ? letter : "#"
  }

  /// Percent-encodes using a conservative query-safe character set.
  var fk_urlEncoded: String {
    addingPercentEncoding(withAllowedCharacters: .fk_urlQueryParameterAllowed) ?? self
  }

  /// Decodes percent-encoded text.
  var fk_urlDecoded: String {
    removingPercentEncoding ?? self
  }

  /// Escapes HTML entities.
  var fk_htmlEscaped: String {
    self
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }

  /// Unescapes HTML entities.
  var fk_htmlUnescaped: String {
    self
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&#39;", with: "'")
      .replacingOccurrences(of: "&amp;", with: "&")
  }
}

private extension CharacterSet {
  static let fk_urlQueryParameterAllowed: CharacterSet = {
    var set = CharacterSet.urlQueryAllowed
    set.remove(charactersIn: "+&=?")
    return set
  }()
}
