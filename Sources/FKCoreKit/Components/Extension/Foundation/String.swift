import Foundation

// MARK: - Whitespace & emptiness

public extension String {
  /// Trims leading and trailing whitespace and newline characters.
  var fk_trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// `true` when the string is empty after trimming whitespace and newlines.
  var fk_isBlank: Bool {
    fk_trimmed.isEmpty
  }

  /// Returns `nil` when the string is empty.
  var fk_nilIfEmpty: String? {
    isEmpty ? nil : self
  }

  /// Returns `nil` when the string is blank after trimming whitespace and newlines.
  var fk_nilIfBlank: String? {
    fk_isBlank ? nil : self
  }
}

// MARK: - Substrings & ranges

public extension String {
  /// Safe substring by extended grapheme cluster offsets; returns empty string when out of range.
  ///
  /// - Parameters:
  ///   - location: Start offset in characters (`Character` count from `startIndex`).
  ///   - length: Maximum number of characters to include.
  func fk_substring(location: Int, length: Int) -> String {
    guard location >= 0, length > 0 else { return "" }
    guard let startIdx = index(startIndex, offsetBy: location, limitedBy: endIndex) else { return "" }
    guard let endIdx = index(startIdx, offsetBy: length, limitedBy: endIndex) else {
      return String(self[startIdx..<endIndex])
    }
    return String(self[startIdx..<endIdx])
  }

  /// Prefix limited to `maxLength` characters (extended grapheme clusters).
  func fk_limitedPrefix(_ maxLength: Int) -> String {
    guard maxLength > 0 else { return "" }
    if count <= maxLength { return self }
    return String(prefix(maxLength))
  }

  /// Middle ellipsis truncation preserving `prefixLength` leading and `suffixLength` trailing characters.
  ///
  /// Example: `"A128839F2"` with prefix 5 and suffix 3 → `"A1288…9F2"`.
  func fk_middleTruncated(
    prefixLength: Int,
    suffixLength: Int,
    separator: String = "…"
  ) -> String {
    guard prefixLength > 0, suffixLength > 0 else { return self }
    let separatorCount = separator.count
    guard count > prefixLength + suffixLength + separatorCount else { return self }
    let head = fk_limitedPrefix(prefixLength)
    let tailStart = count - suffixLength
    let tail = fk_substring(location: tailStart, length: suffixLength)
    return head + separator + tail
  }
}

// MARK: - Encoding & conversion

public extension String {
  /// UTF-8 encoded data.
  var fk_utf8Data: Data {
    Data(utf8)
  }

  /// Creates a URL when the string is a valid URL string; otherwise `nil`.
  var fk_asURL: URL? {
    URL(string: self)
  }

  /// Base64-encoded data when the string is valid base64; otherwise `nil`.
  var fk_base64DecodedData: Data? {
    Data(base64Encoded: self)
  }

  /// UTF-8 text decoded from a Base64 string; otherwise `nil`.
  var fk_base64DecodedString: String? {
    guard let data = fk_base64DecodedData else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// Base64 representation of the UTF-8 bytes.
  var fk_base64EncodedString: String {
    fk_utf8Data.base64EncodedString()
  }
}

// MARK: - Validation helpers

public extension String {
  /// `true` when every character is ASCII digit.
  var fk_isNumericDigitsOnly: Bool {
    !isEmpty && unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
  }

  /// Case-insensitive containment check using the current locale.
  func fk_containsCaseInsensitive(_ other: String) -> Bool {
    range(of: other, options: [.caseInsensitive, .diacriticInsensitive]) != nil
  }
}

// MARK: - Random identifier

public extension String {
  /// Random alphanumeric string of given length using `UUID` sampling (not cryptographically strong).
  static func fk_randomAlphanumeric(length: Int) -> String {
    guard length > 0 else { return "" }
    let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    var result = ""
    result.reserveCapacity(length)
    for _ in 0..<length {
      let idx = Int.random(in: 0..<chars.count)
      result.append(chars[idx])
    }
    return result
  }
}
