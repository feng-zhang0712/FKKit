//
// FKTextFieldDefaultFormatter.swift
//
// Default built-in formatter implementation.
//

import Foundation

/// Default formatter used by `FKTextField`.
public struct FKTextFieldDefaultFormatter: FKTextFieldFormatting {
  /// Creates a default formatter.
  public init() {}

  /// Formats text according to the active input rule.
  public func format(text: String, rule: FKTextFieldInputRule) -> FKTextFieldFormattingResult {
    var candidate = text
    var removedIllegalCharacters = false

    if !rule.allowsEmoji, candidate.fk_containsEmoji {
      candidate = candidate.unicodeScalars.filter { !($0.properties.isEmojiPresentation || $0.properties.isEmoji) }
        .map(String.init)
        .joined()
      removedIllegalCharacters = true
    }

    if !rule.allowsWhitespace {
      let filtered = candidate.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
      removedIllegalCharacters = removedIllegalCharacters || (filtered != candidate)
      candidate = filtered
    }

    let result: FKTextFieldFormattingResult
    switch rule.formatType {
    case .phoneNumber:
      result = formatPhone(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .idCard:
      result = formatIDCard(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .bankCard:
      result = formatBankCard(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case let .verificationCode(length, allowsAlphabet):
      result = formatVerificationCode(
        candidate,
        length: length,
        allowsAlphabet: allowsAlphabet,
        maxLength: rule.maxLength,
        removed: removedIllegalCharacters
      )
    case let .password(_, maxLength, _):
      result = formatPassword(candidate, maxLength: rule.maxLength ?? maxLength, removed: removedIllegalCharacters)
    case let .amount(maxIntegerDigits, decimalDigits):
      result = formatAmount(
        candidate,
        maxIntegerDigits: maxIntegerDigits,
        decimalDigits: decimalDigits,
        removed: removedIllegalCharacters
      )
    case .email:
      result = formatEmail(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .numeric:
      result = formatNumeric(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .alphabetic:
      result = formatAlphabetic(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case .alphaNumeric:
      result = formatAlphaNumeric(candidate, maxLength: rule.maxLength, removed: removedIllegalCharacters)
    case let .custom(regex, maxLength, separator, groupPattern):
      result = formatCustom(
        candidate,
        regex: regex,
        maxLength: maxLength ?? rule.maxLength,
        separator: separator,
        groupPattern: groupPattern,
        removed: removedIllegalCharacters
      )
    }

    if !rule.allowsSpecialCharacters {
      let filteredRaw = result.rawText.filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "@" || $0 == "_" }
      if filteredRaw != result.rawText {
        return FKTextFieldFormattingResult(
          rawText: filteredRaw,
          formattedText: filteredRaw,
          isTruncated: result.isTruncated,
          removedIllegalCharacters: true
        )
      }
    }

    return result
  }
}

private extension FKTextFieldDefaultFormatter {
  func formatPhone(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    let limit = maxLength ?? 11
    let raw = text.fk_digitsOnly.fk_truncated(to: limit)
    let formatted = raw.fk_grouped(pattern: [3, 4, 4])
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.fk_digitsOnly.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatIDCard(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.uppercased().filter { $0.isNumber || $0 == "X" }
    let limit = maxLength ?? 18
    raw = raw.fk_truncated(to: limit)
    let format = raw.count > 15 ? [6, 4, 4, 4] : [6, 4, 5]
    let formatted = raw.fk_grouped(pattern: format)
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text.uppercased())
  }

  func formatBankCard(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    let limit = maxLength ?? 24
    let raw = text.fk_digitsOnly.fk_truncated(to: limit)
    let formatted = raw.fk_grouped(pattern: [4])
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.fk_digitsOnly.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatVerificationCode(
    _ text: String,
    length: Int,
    allowsAlphabet: Bool,
    maxLength: Int?,
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    let maxCount = maxLength ?? max(0, length)
    let raw: String
    if allowsAlphabet {
      raw = text.fk_alphaNumericOnly.uppercased().fk_truncated(to: maxCount)
    } else {
      raw = text.fk_digitsOnly.fk_truncated(to: maxCount)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatPassword(_ text: String, maxLength: Int, removed: Bool) -> FKTextFieldFormattingResult {
    let raw = text.fk_truncated(to: max(0, maxLength))
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed)
  }

  func formatAmount(
    _ text: String,
    maxIntegerDigits: Int,
    decimalDigits: Int,
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    let filtered = text.filter { $0.isNumber || $0 == "." }
    let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
    let integerRaw = String(parts.first ?? "").fk_digitsOnly.fk_truncated(to: max(1, maxIntegerDigits))
    let decimalRaw = parts.count > 1 ? String(parts[1]).fk_digitsOnly.fk_truncated(to: max(0, decimalDigits)) : ""
    let groupedInteger = groupThousands(integerRaw)
    let formatted = decimalRaw.isEmpty ? groupedInteger : "\(groupedInteger).\(decimalRaw)"
    let raw = decimalRaw.isEmpty ? integerRaw : "\(integerRaw).\(decimalRaw)"
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < filtered.count, removedIllegalCharacters: removed || filtered != text)
  }

  func groupThousands(_ digits: String) -> String {
    guard digits.count > 3 else { return digits }
    var out: [Character] = []
    out.reserveCapacity(digits.count + digits.count / 3)
    var counter = 0
    for ch in digits.reversed() {
      if counter > 0, counter % 3 == 0 {
        out.append(",")
      }
      out.append(ch)
      counter += 1
    }
    return String(out.reversed())
  }

  func formatEmail(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.lowercased()
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed)
  }

  func formatNumeric(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_digitsOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatAlphabetic(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_lettersOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatAlphaNumeric(_ text: String, maxLength: Int?, removed: Bool) -> FKTextFieldFormattingResult {
    var raw = text.fk_alphaNumericOnly
    if let maxLength {
      raw = raw.fk_truncated(to: maxLength)
    }
    return .init(rawText: raw, formattedText: raw, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }

  func formatCustom(
    _ text: String,
    regex: String,
    maxLength: Int?,
    separator: Character?,
    groupPattern: [Int],
    removed: Bool
  ) -> FKTextFieldFormattingResult {
    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
    let raw = text.filter { predicate.evaluate(with: String($0)) }
      .fk_truncated(to: maxLength ?? .max)
    let formatted: String
    if let separator, !groupPattern.isEmpty {
      formatted = raw.fk_grouped(separator: separator, pattern: groupPattern)
    } else {
      formatted = raw
    }
    return .init(rawText: raw, formattedText: formatted, isTruncated: raw.count < text.count, removedIllegalCharacters: removed || raw != text)
  }
}

