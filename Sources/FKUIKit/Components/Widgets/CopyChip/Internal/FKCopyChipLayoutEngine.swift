import CoreGraphics
import FKCoreKit
import UIKit

enum FKCopyChipTextFormatter {
  static func displayString(text: String, layout: FKCopyChipLayoutConfiguration) -> String {
    let body: String
    switch layout.truncation {
    case .none:
      body = text
    case .tail(let maxCharacters):
      body = text.fk_limitedPrefix(maxCharacters)
    case .middle(let prefixLength, let suffixLength):
      body = text.fk_middleTruncated(prefixLength: prefixLength, suffixLength: suffixLength)
    }
    if let prefix = layout.prefix, !prefix.isEmpty {
      return prefix + body
    }
    return body
  }

  /// Short summary for accessibility (truncated display without over-long pasteboard values).
  static func accessibilitySummary(text: String, layout: FKCopyChipLayoutConfiguration) -> String {
    displayString(text: text, layout: layout)
  }
}

enum FKCopyChipLayoutEngine {
  struct Metrics: Equatable {
    var size: CGSize
    var cornerRadius: CGFloat
    var textFrame: CGRect
    var iconFrame: CGRect
  }

  struct Input: Equatable {
    var displayText: String
    var font: UIFont
    var height: CGFloat
    var horizontalPadding: CGFloat
    var iconSpacing: CGFloat
    var iconPointSize: CGFloat
  }

  static func layout(
    _ input: Input,
    layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
  ) -> Metrics {
    let iconSide = input.iconPointSize
    let isRTL = layoutDirection == .rightToLeft

    let iconBlock = iconSide + input.iconSpacing
    let textMaxWidth = CGFloat.greatestFiniteMagnitude
    let textSize = (input.displayText as NSString).boundingRect(
      with: CGSize(width: textMaxWidth, height: input.height),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: input.font],
      context: nil
    ).size

    let contentWidth = input.horizontalPadding
      + ceil(textSize.width)
      + iconBlock
      + input.horizontalPadding

    let width = max(input.height, contentWidth)
    let height = input.height

    let textFrame: CGRect
    let iconFrame: CGRect
    if isRTL {
      let iconX = input.horizontalPadding
      iconFrame = CGRect(
        x: iconX,
        y: (height - iconSide) / 2,
        width: iconSide,
        height: iconSide
      )
      let textX = iconX + iconBlock
      textFrame = CGRect(
        x: textX,
        y: 0,
        width: max(0, width - textX - input.horizontalPadding),
        height: height
      )
    } else {
      textFrame = CGRect(
        x: input.horizontalPadding,
        y: 0,
        width: max(0, width - input.horizontalPadding * 2 - iconBlock),
        height: height
      )
      iconFrame = CGRect(
        x: width - input.horizontalPadding - iconSide,
        y: (height - iconSide) / 2,
        width: iconSide,
        height: iconSide
      )
    }

    return Metrics(
      size: CGSize(width: width, height: height),
      cornerRadius: height / 2,
      textFrame: textFrame,
      iconFrame: iconFrame
    )
  }

  /// Leading- or trailing-aligned pill frame inside ``bounds`` (never stretches past natural width).
  static func pillFrame(
    metrics: Metrics,
    in bounds: CGRect,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> CGRect {
    let width = bounds.width > 0 ? min(metrics.size.width, bounds.width) : metrics.size.width
    let height = bounds.height > 0 ? min(metrics.size.height, bounds.height) : metrics.size.height
    let size = CGSize(width: width, height: height)
    let originY = max(0, (bounds.height - height) / 2)
    let originX: CGFloat = switch layoutDirection {
    case .rightToLeft: max(0, bounds.width - width)
    default: 0
    }
    return CGRect(origin: CGPoint(x: originX, y: originY), size: size)
  }
}
