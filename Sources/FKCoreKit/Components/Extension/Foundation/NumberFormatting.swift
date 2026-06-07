import Foundation

public extension Decimal {
  /// Formats the decimal with grouping separators.
  func fk_formattedAmount(
    minimumFractionDigits: Int = 2,
    maximumFractionDigits: Int = 2,
    locale: Locale = .current
  ) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = locale
    formatter.minimumFractionDigits = minimumFractionDigits
    formatter.maximumFractionDigits = maximumFractionDigits
    return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
  }

  /// Truncates toward zero at the given scale.
  func fk_truncated(scale: Int) -> Decimal {
    fk_rounded(scale: scale, mode: .down)
  }
}

public extension Double {
  /// Formats the value as a localized percent string.
  func fk_formattedPercent(fractionDigits: Int = 2, locale: Locale = .current) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.locale = locale
    formatter.minimumFractionDigits = fractionDigits
    formatter.maximumFractionDigits = fractionDigits
    return formatter.string(from: NSNumber(value: self)) ?? "\(self * 100)%"
  }

  /// Formats large values using Chinese `万` / `亿` units.
  func fk_formattedChineseUnit(fractionDigits: Int = 2) -> String {
    let absolute = abs(self)
    if absolute >= 100_000_000 {
      return "\((self / 100_000_000).fk_fixedDigits(fractionDigits))亿"
    }
    if absolute >= 10_000 {
      return "\((self / 10_000).fk_fixedDigits(fractionDigits))万"
    }
    return fk_fixedDigits(fractionDigits)
  }

  /// Compact readable representation (for example `1.2K`, `3.4M`).
  func fk_compactFormatted(locale: Locale = .current) -> String {
    if #available(iOS 15.0, *) {
      let style = FloatingPointFormatStyle<Double>.number
        .locale(locale)
        .notation(.compactName)
      return formatted(style)
    }
    let absolute = abs(self)
    if absolute >= 1_000_000_000 { return String(format: "%.1fB", self / 1_000_000_000) }
    if absolute >= 1_000_000 { return String(format: "%.1fM", self / 1_000_000) }
    if absolute >= 1_000 { return String(format: "%.1fK", self / 1_000) }
    return String(format: "%.0f", self)
  }

  fileprivate func fk_fixedDigits(_ digits: Int) -> String {
    String(format: "%.\(max(0, digits))f", self)
  }
}

public extension Int {
  /// Left-pads with zeros to reach `length` characters.
  func fk_zeroPadded(toLength length: Int) -> String {
    String(format: "%0\(Swift.max(0, length))d", self)
  }
}

public extension Int64 {
  /// Compact readable representation using locale-aware compact notation when available.
  func fk_compactFormatted(locale: Locale = .current) -> String {
    if #available(iOS 15.0, *) {
      let style: IntegerFormatStyle<Int64> = .number.locale(locale).notation(.compactName)
      return formatted(style)
    }
    let absolute = abs(Double(self))
    if absolute >= 1_000_000_000 { return String(format: "%.1fB", Double(self) / 1_000_000_000) }
    if absolute >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
    if absolute >= 1_000 { return String(format: "%.1fK", Double(self) / 1_000) }
    return "\(self)"
  }
}
