//
// String+FKTextField.swift
//
// String helpers for FKTextField formatting.
//

import Foundation

extension String {
  /// Returns a string that keeps only decimal digits.
  var fk_digitsOnly: String {
    filter(\.isNumber)
  }

  /// Returns a string that keeps only ASCII letters.
  var fk_lettersOnly: String {
    filter { $0.isASCII && $0.isLetter }
  }

  /// Returns a string that keeps only ASCII letters and numbers.
  var fk_alphaNumericOnly: String {
    filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
  }

  /// Returns whether the string contains emoji scalar.
  var fk_containsEmoji: Bool {
    unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
  }

  /// Returns a grouped representation.
  func fk_grouped(separator: Character = " ", pattern: [Int]) -> String {
    guard !pattern.isEmpty else { return self }
    var output = ""
    var index = startIndex
    var patternIndex = 0
    while index < endIndex {
      let groupLength = pattern[min(patternIndex, pattern.count - 1)]
      guard groupLength > 0 else { break }
      let nextIndex = self.index(index, offsetBy: groupLength, limitedBy: endIndex) ?? endIndex
      if !output.isEmpty {
        output.append(separator)
      }
      output.append(contentsOf: self[index..<nextIndex])
      index = nextIndex
      if patternIndex < pattern.count - 1 {
        patternIndex += 1
      }
    }
    return output
  }

  /// Truncates string to a maximum count.
  func fk_truncated(to count: Int) -> String {
    guard count >= 0 else { return "" }
    if self.count <= count {
      return self
    }
    return String(prefix(count))
  }
}

