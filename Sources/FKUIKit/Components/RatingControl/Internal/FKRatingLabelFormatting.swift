import UIKit

enum FKRatingLabelFormatting {
  static func labelText(
    value: Double,
    configuration: FKRatingConfiguration
  ) -> String? {
    guard configuration.layout.labelPlacement != .none else { return nil }
    if let custom = configuration.label.customText, !custom.isEmpty {
      return custom
    }
    let formatter = configuration.appearance.valueNumberFormatter ?? defaultFormatter
    let numeric = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    return configuration.label.valuePrefix + numeric + configuration.label.valueSuffix
  }

  static func labelSize(
    value: Double,
    configuration: FKRatingConfiguration
  ) -> CGSize {
    guard let text = labelText(value: value, configuration: configuration) else { return .zero }
    let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    let rect = (text as NSString).boundingRect(
      with: maxSize,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: configuration.appearance.labelFont],
      context: nil
    )
  // Extra vertical slack avoids clipping descenders and line-leading in tight stacks.
    return CGSize(width: ceil(rect.width), height: ceil(rect.height) + 2)
  }

  static func accessibilityValue(
    value: Double,
    maximumValue: Double,
    configuration: FKRatingConfiguration
  ) -> String {
    let formatter = configuration.appearance.valueNumberFormatter ?? defaultFormatter
    let valueText = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    let maxText = formatter.string(from: NSNumber(value: maximumValue)) ?? "\(maximumValue)"
    return String(format: configuration.accessibility.valueFormat, valueText, maxText)
  }

  private static let defaultFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.numberStyle = .decimal
    return formatter
  }()
}
